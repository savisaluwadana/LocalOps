# Kubeflow Training Pipeline

import kfp
from kfp import dsl
from kfp.dsl import (
    component,
    Input,
    Output,
    Dataset,
    Model,
    Metrics,
    ClassificationMetrics,
)
from typing import NamedTuple

# ==============================================================================
# COMPONENT DEFINITIONS
# ==============================================================================

@component(
    base_image='python:3.10-slim',
    packages_to_install=['pandas', 'numpy', 'scikit-learn', 'pyarrow']
)
def load_data(
    data_path: str,
    output_dataset: Output[Dataset],
    split_ratio: float = 0.2
) -> NamedTuple('Outputs', [('num_samples', int), ('num_features', int)]):
    """Load and split dataset."""
    import pandas as pd
    from sklearn.model_selection import train_test_split
    import json
    
    # Load data
    df = pd.read_parquet(data_path)
    
    # Split data
    train_df, test_df = train_test_split(df, test_size=split_ratio, random_state=42)
    
    # Save datasets
    train_df.to_parquet(f'{output_dataset.path}/train.parquet')
    test_df.to_parquet(f'{output_dataset.path}/test.parquet')
    
    # Metadata
    output_dataset.metadata['num_train_samples'] = len(train_df)
    output_dataset.metadata['num_test_samples'] = len(test_df)
    output_dataset.metadata['features'] = list(df.columns)
    
    return (len(df), len(df.columns) - 1)


@component(
    base_image='python:3.10-slim',
    packages_to_install=['pandas', 'numpy', 'great_expectations']
)
def validate_data(
    input_dataset: Input[Dataset],
    validation_report: Output[Dataset],
) -> NamedTuple('Outputs', [('is_valid', bool), ('num_issues', int)]):
    """Validate data quality using Great Expectations."""
    import pandas as pd
    import great_expectations as ge
    import json
    
    # Load data
    train_df = pd.read_parquet(f'{input_dataset.path}/train.parquet')
    
    # Create GE DataFrame
    ge_df = ge.from_pandas(train_df)
    
    # Define expectations
    results = []
    
    # Check for missing values
    for col in train_df.columns:
        result = ge_df.expect_column_values_to_not_be_null(col)
        results.append(result)
    
    # Check value ranges
    numeric_cols = train_df.select_dtypes(include=['number']).columns
    for col in numeric_cols:
        min_val = train_df[col].min()
        max_val = train_df[col].max()
        result = ge_df.expect_column_values_to_be_between(col, min_val, max_val)
        results.append(result)
    
    # Aggregate results
    num_failures = sum(1 for r in results if not r.success)
    is_valid = num_failures == 0
    
    # Save validation report
    report = {
        'is_valid': is_valid,
        'num_expectations': len(results),
        'num_failures': num_failures,
        'results': [r.to_json_dict() for r in results]
    }
    
    with open(f'{validation_report.path}/report.json', 'w') as f:
        json.dump(report, f)
    
    return (is_valid, num_failures)


@component(
    base_image='python:3.10-slim',
    packages_to_install=['pandas', 'numpy', 'scikit-learn', 'feast']
)
def feature_engineering(
    input_dataset: Input[Dataset],
    output_features: Output[Dataset],
    feature_store_path: str = '',
) -> NamedTuple('Outputs', [('num_features', int)]):
    """Extract and transform features."""
    import pandas as pd
    from sklearn.preprocessing import StandardScaler, LabelEncoder
    import numpy as np
    
    # Load data
    train_df = pd.read_parquet(f'{input_dataset.path}/train.parquet')
    test_df = pd.read_parquet(f'{input_dataset.path}/test.parquet')
    
    # Identify feature types
    numeric_cols = train_df.select_dtypes(include=['number']).columns.tolist()
    categorical_cols = train_df.select_dtypes(include=['object', 'category']).columns.tolist()
    
    # Remove target column from features
    target_col = 'target'  # Assuming 'target' is the label column
    if target_col in numeric_cols:
        numeric_cols.remove(target_col)
    
    # Scale numeric features
    scaler = StandardScaler()
    train_df[numeric_cols] = scaler.fit_transform(train_df[numeric_cols])
    test_df[numeric_cols] = scaler.transform(test_df[numeric_cols])
    
    # Encode categorical features
    encoders = {}
    for col in categorical_cols:
        if col != target_col:
            le = LabelEncoder()
            train_df[col] = le.fit_transform(train_df[col].astype(str))
            test_df[col] = le.transform(test_df[col].astype(str))
            encoders[col] = le
    
    # Save processed features
    train_df.to_parquet(f'{output_features.path}/train_features.parquet')
    test_df.to_parquet(f'{output_features.path}/test_features.parquet')
    
    # Save transformers
    import pickle
    with open(f'{output_features.path}/scaler.pkl', 'wb') as f:
        pickle.dump(scaler, f)
    with open(f'{output_features.path}/encoders.pkl', 'wb') as f:
        pickle.dump(encoders, f)
    
    output_features.metadata['numeric_features'] = numeric_cols
    output_features.metadata['categorical_features'] = categorical_cols
    
    return (len(numeric_cols) + len(categorical_cols),)


@component(
    base_image='python:3.10-slim',
    packages_to_install=[
        'pandas', 'numpy', 'scikit-learn', 'xgboost', 
        'mlflow', 'lightgbm', 'optuna'
    ]
)
def train_model(
    input_features: Input[Dataset],
    output_model: Output[Model],
    metrics: Output[Metrics],
    model_type: str = 'xgboost',
    hyperparameters: dict = {},
    mlflow_tracking_uri: str = ''
) -> NamedTuple('Outputs', [('accuracy', float), ('f1_score', float)]):
    """Train ML model with hyperparameter tuning."""
    import pandas as pd
    import numpy as np
    from sklearn.model_selection import cross_val_score
    from sklearn.metrics import accuracy_score, f1_score, classification_report
    import mlflow
    import pickle
    import json
    
    # Set MLflow tracking
    if mlflow_tracking_uri:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
    
    # Load features
    train_df = pd.read_parquet(f'{input_features.path}/train_features.parquet')
    
    # Prepare data
    target_col = 'target'
    X_train = train_df.drop(columns=[target_col])
    y_train = train_df[target_col]
    
    # Default hyperparameters
    default_params = {
        'xgboost': {
            'n_estimators': 100,
            'max_depth': 6,
            'learning_rate': 0.1,
            'subsample': 0.8,
            'colsample_bytree': 0.8,
            'random_state': 42
        },
        'lightgbm': {
            'n_estimators': 100,
            'max_depth': -1,
            'learning_rate': 0.1,
            'num_leaves': 31,
            'random_state': 42
        },
        'random_forest': {
            'n_estimators': 100,
            'max_depth': None,
            'min_samples_split': 2,
            'random_state': 42
        }
    }
    
    params = {**default_params.get(model_type, {}), **hyperparameters}
    
    # Initialize model
    if model_type == 'xgboost':
        import xgboost as xgb
        model = xgb.XGBClassifier(**params)
    elif model_type == 'lightgbm':
        import lightgbm as lgb
        model = lgb.LGBMClassifier(**params)
    else:
        from sklearn.ensemble import RandomForestClassifier
        model = RandomForestClassifier(**params)
    
    # Train with MLflow tracking
    with mlflow.start_run():
        # Log parameters
        mlflow.log_params(params)
        
        # Cross-validation
        cv_scores = cross_val_score(model, X_train, y_train, cv=5, scoring='accuracy')
        mlflow.log_metric('cv_accuracy_mean', cv_scores.mean())
        mlflow.log_metric('cv_accuracy_std', cv_scores.std())
        
        # Train final model
        model.fit(X_train, y_train)
        
        # Predictions
        y_pred = model.predict(X_train)
        train_accuracy = accuracy_score(y_train, y_pred)
        train_f1 = f1_score(y_train, y_pred, average='weighted')
        
        # Log metrics
        mlflow.log_metric('train_accuracy', train_accuracy)
        mlflow.log_metric('train_f1', train_f1)
        
        # Save model
        with open(f'{output_model.path}/model.pkl', 'wb') as f:
            pickle.dump(model, f)
        
        # Log model to MLflow
        mlflow.sklearn.log_model(model, 'model')
        
        # Feature importance
        if hasattr(model, 'feature_importances_'):
            importance = dict(zip(X_train.columns, model.feature_importances_))
            with open(f'{output_model.path}/feature_importance.json', 'w') as f:
                json.dump(importance, f)
    
    # Log metrics to Kubeflow
    metrics.log_metric('accuracy', train_accuracy)
    metrics.log_metric('f1_score', train_f1)
    metrics.log_metric('cv_accuracy', cv_scores.mean())
    
    output_model.metadata['model_type'] = model_type
    output_model.metadata['hyperparameters'] = params
    
    return (train_accuracy, train_f1)


@component(
    base_image='python:3.10-slim',
    packages_to_install=['pandas', 'numpy', 'scikit-learn']
)
def evaluate_model(
    input_model: Input[Model],
    input_features: Input[Dataset],
    metrics: Output[ClassificationMetrics],
    evaluation_report: Output[Dataset],
) -> NamedTuple('Outputs', [('test_accuracy', float), ('test_f1', float)]):
    """Evaluate model on test data."""
    import pandas as pd
    import numpy as np
    from sklearn.metrics import (
        accuracy_score, f1_score, precision_score, recall_score,
        confusion_matrix, classification_report, roc_auc_score
    )
    import pickle
    import json
    
    # Load model
    with open(f'{input_model.path}/model.pkl', 'rb') as f:
        model = pickle.load(f)
    
    # Load test data
    test_df = pd.read_parquet(f'{input_features.path}/test_features.parquet')
    
    target_col = 'target'
    X_test = test_df.drop(columns=[target_col])
    y_test = test_df[target_col]
    
    # Predictions
    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test) if hasattr(model, 'predict_proba') else None
    
    # Calculate metrics
    test_accuracy = accuracy_score(y_test, y_pred)
    test_f1 = f1_score(y_test, y_pred, average='weighted')
    test_precision = precision_score(y_test, y_pred, average='weighted')
    test_recall = recall_score(y_test, y_pred, average='weighted')
    
    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    classes = list(map(str, np.unique(y_test)))
    
    # Log to Kubeflow metrics
    metrics.log_confusion_matrix(
        categories=classes,
        matrix=cm.tolist()
    )
    
    # ROC AUC for binary classification
    if len(classes) == 2 and y_proba is not None:
        roc_auc = roc_auc_score(y_test, y_proba[:, 1])
        metrics.log_roc_curve(
            fpr=[], tpr=[], threshold=[]  # Placeholder
        )
    else:
        roc_auc = None
    
    # Save evaluation report
    report = {
        'accuracy': test_accuracy,
        'f1_score': test_f1,
        'precision': test_precision,
        'recall': test_recall,
        'roc_auc': roc_auc,
        'classification_report': classification_report(y_test, y_pred, output_dict=True),
        'confusion_matrix': cm.tolist()
    }
    
    with open(f'{evaluation_report.path}/evaluation.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    return (test_accuracy, test_f1)


@component(
    base_image='python:3.10-slim',
    packages_to_install=['mlflow', 'boto3']
)
def register_model(
    input_model: Input[Model],
    model_name: str,
    model_stage: str = 'Staging',
    mlflow_tracking_uri: str = ''
) -> str:
    """Register model to MLflow Model Registry."""
    import mlflow
    from mlflow.tracking import MlflowClient
    
    if mlflow_tracking_uri:
        mlflow.set_tracking_uri(mlflow_tracking_uri)
    
    client = MlflowClient()
    
    # Register model
    model_uri = f'{input_model.path}/model.pkl'
    
    # Create or get model in registry
    try:
        client.create_registered_model(model_name)
    except:
        pass  # Model already exists
    
    # Log and register
    with mlflow.start_run():
        mlflow.log_artifact(model_uri)
        result = mlflow.register_model(
            f'runs:/{mlflow.active_run().info.run_id}/model.pkl',
            model_name
        )
    
    # Transition to stage
    client.transition_model_version_stage(
        name=model_name,
        version=result.version,
        stage=model_stage
    )
    
    return f'{model_name}/{result.version}'


# ==============================================================================
# PIPELINE DEFINITION
# ==============================================================================

@dsl.pipeline(
    name='ML Training Pipeline',
    description='End-to-end ML training pipeline with validation and registration'
)
def ml_training_pipeline(
    data_path: str = 's3://data-bucket/datasets/training.parquet',
    model_name: str = 'classification-model',
    model_type: str = 'xgboost',
    mlflow_tracking_uri: str = 'http://mlflow:5000',
    min_accuracy: float = 0.85,
):
    # Load data
    load_task = load_data(data_path=data_path)
    
    # Validate data
    validate_task = validate_data(input_dataset=load_task.outputs['output_dataset'])
    
    # Continue only if data is valid
    with dsl.Condition(validate_task.outputs['is_valid'] == True):
        # Feature engineering
        feature_task = feature_engineering(
            input_dataset=load_task.outputs['output_dataset']
        )
        
        # Train model
        train_task = train_model(
            input_features=feature_task.outputs['output_features'],
            model_type=model_type,
            mlflow_tracking_uri=mlflow_tracking_uri
        )
        
        # Evaluate model
        evaluate_task = evaluate_model(
            input_model=train_task.outputs['output_model'],
            input_features=feature_task.outputs['output_features']
        )
        
        # Register if accuracy threshold met
        with dsl.Condition(evaluate_task.outputs['test_accuracy'] >= min_accuracy):
            register_task = register_model(
                input_model=train_task.outputs['output_model'],
                model_name=model_name,
                mlflow_tracking_uri=mlflow_tracking_uri
            )


if __name__ == '__main__':
    kfp.compiler.Compiler().compile(
        ml_training_pipeline,
        'ml_training_pipeline.yaml'
    )
