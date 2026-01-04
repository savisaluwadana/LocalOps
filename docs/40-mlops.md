# MLOps: The Technical Masterclass

## Table of Contents
1.  [The Feature Store (Feast Implementation)](#the-feature-store-feast-implementation)
2.  [Model Registry & CI/CD (MLflow)](#model-registry--cicd-mlflow)
3.  [Drift Detection: Math & Code](#drift-detection-math--code)
4.  [Serving: Optimizing Inference](#serving-optimizing-inference)
5.  [Project: End-to-End Churn Pipeline](#project-end-to-end-churn-pipeline)

---

## 1. The Feature Store (Feast Implementation)

**Theory**: A Feature Store ensures consistency between training (Offline) and serving (Online).
**Example**: Your model needs "Total Transactions Last 24h". In training, you calculate this via SQL sum. In serving, you can't run a slow SQL query; you need a pre-computed value from Redis.

### Implementation with Feast

**Define your Features (`features.py`)**:
```python
from datetime import timedelta
from feast import Entity, FeatureView, Field, FileSource
from feast.types import Float32, Int64

# 1. Define the Entity used to lookup features (e.g. User ID)
user = Entity(name="user_id", join_keys=["user_id"])

# 2. Define the Batch Source (Parquet/SQL)
driver_stats = FileSource(
    path="/data/driver_stats.parquet",
    timestamp_field="event_timestamp"
)

# 3. Define the Feature View (Logic)
driver_activity_view = FeatureView(
    name="driver_activity",
    entities=[user],
    ttl=timedelta(days=1),
    schema=[
        Field(name="conv_rate", dtype=Float32),
        Field(name="acc_rate", dtype=Float32),
        Field(name="avg_daily_trips", dtype=Int64),
    ],
    online=True,  # Sync to Redis
    source=driver_stats,
)
```

**Training Retrieval (Historical)**:
```python
training_df = store.get_historical_features(
    entity_df=entity_df, # List of UserIDs and Timestamps
    features=["driver_activity:conv_rate"]
).to_df()
```

**Serving Retrieval (Online - Low Latency)**:
```python
online_features = store.get_online_features(
    features=["driver_activity:conv_rate"],
    entity_rows=[{"user_id": 1001}]
).to_dict()
# Returns: {'conv_rate': 0.54} in < 10ms from Redis
```

---

## 2. Model Registry & CI/CD (MLflow)

**Theory**: The Registry is the "DockerHub" for models. CI/CD should auto-promote models based on metric thresholds.

### CI/CD Workflow Script (`evaluate.py`)

This script runs in GitHub Actions after training.

```python
import mlflow

def evaluate_and_promote():
    client = mlflow.tracking.MlflowClient()
    
    # 1. Get the latest run
    run_id = "a1b2c3d4..."
    metrics = client.get_run(run_id).data.metrics
    
    # 2. Compare against production baseline
    if metrics["accuracy"] > 0.95 and metrics["latency_ms"] < 200:
        print("✅ Promoting model to Staging")
        
        # 3. Transition Stage programmatically
        client.transition_model_version_stage(
            name="churn_predictor",
            version=1,
            stage="Staging"
        )
    else:
        print("❌ Model failed criteria.")
        exit(1)
```

---

## 3. Drift Detection: Math & Code

**Theory**: How do we mathematically prove "The data has changed"?

### Kolmogorov-Smirnov (K-S) Test
Standard for continuous data (e.g., "Age"). Compares two cumulative distribution functions (reference vs current).

**Python Implementation**:
```python
from scipy.stats import ks_2samp
import numpy as np

# Reference data (Training set)
ref_age = np.random.normal(30, 5, 1000)

# Production data (Live traffic - slightly shifted)
curr_age = np.random.normal(35, 5, 1000)

# Run K-S Test
statistic, p_value = ks_2samp(ref_age, curr_age)

print(f"P-Value: {p_value}")

if p_value < 0.05:
    print("🚨 DATA DRIFT DETECTED! (The distributions are significantly different)")
else:
    print("✅ No Drift")
```

### Population Stability Index (PSI)
Used in Fintech/Banking.
-   `PSI < 0.1`: No change.
-   `PSI 0.1 - 0.25`: Minor drift.
-   `PSI > 0.25`: Major drift.

---

## 4. Serving: Optimizing Inference

Running `model.predict()` in Flask is not enough for scale.

### Optimization Techniques
1.  **Quantization**: Convert weights from Float32 to Int8.
    -   *Impact*: 4x smaller model, 3x faster inference, <1% accuracy loss.
2.  **Batching**: Wait 10ms to collect 10 requests, then process them as a matrix.
    -   *Why*: GPUs love matrices. Processing 1 item takes 10ms. Processing 10 items also takes ~12ms.

### Triton Inference Server (NVIDIA) config
Standard production server.
```protobuf
name: "yolo_model"
platform: "onnxruntime_onnx"
max_batch_size: 16
input [
  {
    name: "images"
    data_type: TYPE_FP32
    dims: [ 3, 640, 640 ]
  }
]
# Enable Dynamic Batching
dynamic_batching {
  preferred_batch_size: [ 4, 8, 16 ]
  max_queue_delay_microseconds: 100
}
```

---

## 5. Project: End-to-End Churn Pipeline

**Goal**: Build a system where a `git push` triggers training, and if successful, auto-deploys a REST API.

### Technology Stack
-   **Data Versioning**: DVC (Data Version Control)
-   **Experiment Tracking**: MLflow
-   **CI/CD**: GitHub Actions
-   **Serving**: FastAPI + Docker
-   **Infra**: Kubernetes

### Step 1: Data Versioning (DVC)
Don't verify 10GB CSVs into Git.
```bash
dvc init
dvc add data/churn.csv
git add data/churn.csv.dvc .gitignore
git commit -m "Track data"
dvc push  # Pushes data to S3
```

### Step 2: Training Pipeline (`train.py`)
```python
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
import mlflow

# Auto-log everything (params, metrics, model artifact)
mlflow.sklearn.autolog()

with mlflow.start_run():
    df = pd.read_csv("data/churn.csv")
    X, y = df.drop("churn", axis=1), df["churn"]
    
    clf = RandomForestClassifier(n_estimators=100)
    clf.fit(X, y)
    
    # Model is now saved in mlruns/ and ready for registry
```

### Step 3: CI/CD Pipeline (`.github/workflows/mlops.yaml`)
```yaml
name: Train and Deploy
on: [push]
jobs:
  train:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Pull Data
        run: dvc pull
      - name: Train Model
        run: python train.py
      - name: Evaluate
        run: python evaluate.py  # Checks drift/accuracy
      - name: Build Docker Image
        if: success()
        run: |
          docker build -t my-app:latest .
          docker push my-app:latest
```

### Step 4: The FastAPI App (`app.py`)
```python
import mlflow.pyfunc
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

# Load model ONCE at startup (Global memory)
model = mlflow.pyfunc.load_model("models:/churn_predictor/Production")

class Customer(BaseModel):
    age: int
    usage_minutes: float

@app.post("/predict")
def predict(customer: Customer):
    data = [[customer.age, customer.usage_minutes]]
    prediction = model.predict(data)
    return {"churn_risk": int(prediction[0])}
```
