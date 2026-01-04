# Tool Integration Guide

This guide demonstrates how all DevOps tools work **together** in real-world scenarios. Each section builds on the previous, showing the complete lifecycle from code to production.

---

## The Big Picture: How Everything Connects

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              DEVOPS TOOL INTEGRATION                                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│   DEVELOPER                                                                              │
│      │                                                                                   │
│      ▼                                                                                   │
│   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────────┐ │
│   │   Git    │────►│ Jenkins  │────►│  Docker  │────►│Terraform │────►│ Kubernetes   │ │
│   │ (Code)   │     │ (CI/CD)  │     │ (Build)  │     │(Provision)│    │ (Orchestrate)│ │
│   └──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────────┘ │
│                          │                                                   │          │
│                          ▼                                                   ▼          │
│                    ┌──────────┐                                       ┌──────────────┐ │
│                    │ Ansible  │──────────────────────────────────────►│  Linux VMs   │ │
│                    │(Configure)│                                       │  (Servers)   │ │
│                    └──────────┘                                       └──────────────┘ │
│                                                                              │          │
│                                                                              ▼          │
│                                                                       ┌──────────────┐ │
│                                                                       │ Prometheus   │ │
│                                                                       │ + Grafana    │ │
│                                                                       │ (Monitor)    │ │
│                                                                       └──────────────┘ │
│                                                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### The Flow Explained

1. **Developer** writes code and pushes to **Git**
2. **Jenkins** detects the push and starts a CI/CD pipeline
3. **Docker** builds a container image from the code
4. **Terraform** provisions the infrastructure (K8s cluster, databases, etc.)
5. **Ansible** configures any Linux VMs with required software
6. **Kubernetes** deploys and manages the containerized application
7. **Prometheus/Grafana** monitors everything and alerts on issues

---

## Scenario 1: Complete Web Application Deployment

We'll deploy a Python Flask app with PostgreSQL database, from scratch.

### Step 1: The Application Code

Create `app/app.py`:
```python
from flask import Flask, jsonify
import psycopg2
import os

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        database=os.environ.get('DB_NAME', 'myapp'),
        user=os.environ.get('DB_USER', 'postgres'),
        password=os.environ.get('DB_PASSWORD', 'password')
    )

@app.route('/')
def index():
    return jsonify({"status": "healthy", "app": "myflaskapp"})

@app.route('/users')
def get_users():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM users;')
    users = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(users)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Step 2: Dockerize the Application

Create `app/Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create non-root user
RUN useradd -m appuser && chown -R appuser /app
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
```

Create `app/requirements.txt`:
```
flask==3.0.0
psycopg2-binary==2.9.9
gunicorn==21.0.0
```

**Build and test locally:**
```bash
cd app
docker build -t myflaskapp:v1 .
docker run -p 5000:5000 myflaskapp:v1
curl http://localhost:5000
```

### Step 3: Provision Infrastructure with Terraform

Create `terraform/main.tf`:
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# Create network for app and database
resource "docker_network" "app_network" {
  name = "myapp-network"
}

# PostgreSQL Database
resource "docker_image" "postgres" {
  name = "postgres:15-alpine"
}

resource "docker_container" "postgres" {
  name  = "myapp-db"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.app_network.name
  }

  env = [
    "POSTGRES_USER=appuser",
    "POSTGRES_PASSWORD=secretpassword",
    "POSTGRES_DB=myapp"
  ]

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U appuser -d myapp"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

resource "docker_volume" "postgres_data" {
  name = "myapp-postgres-data"
}

# Application Container
resource "docker_image" "app" {
  name = "myflaskapp:v1"
}

resource "docker_container" "app" {
  name  = "myapp-web"
  image = docker_image.app.image_id

  networks_advanced {
    name = docker_network.app_network.name
  }

  ports {
    internal = 5000
    external = 8080
  }

  env = [
    "DB_HOST=myapp-db",
    "DB_NAME=myapp",
    "DB_USER=appuser",
    "DB_PASSWORD=secretpassword"
  ]

  depends_on = [docker_container.postgres]
}

output "app_url" {
  value = "http://localhost:8080"
}
```

**Apply infrastructure:**
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### Step 4: Configure Database with Ansible

Create `ansible/setup_db.yml`:
```yaml
---
- name: Initialize Database
  hosts: localhost
  connection: local
  gather_facts: no

  vars:
    db_host: localhost
    db_port: 5432
    db_name: myapp
    db_user: appuser
    db_password: secretpassword

  tasks:
    - name: Wait for PostgreSQL to be ready
      wait_for:
        host: "{{ db_host }}"
        port: "{{ db_port }}"
        delay: 5
        timeout: 60

    - name: Create users table
      community.postgresql.postgresql_query:
        login_host: "{{ db_host }}"
        login_user: "{{ db_user }}"
        login_password: "{{ db_password }}"
        db: "{{ db_name }}"
        query: |
          CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) NOT NULL,
            email VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );

    - name: Insert sample data
      community.postgresql.postgresql_query:
        login_host: "{{ db_host }}"
        login_user: "{{ db_user }}"
        login_password: "{{ db_password }}"
        db: "{{ db_name }}"
        query: |
          INSERT INTO users (username, email)
          VALUES ('john', 'john@example.com'), ('jane', 'jane@example.com')
          ON CONFLICT DO NOTHING;
```

**Run the playbook:**
```bash
pip install psycopg2-binary  # For the postgresql module
ansible-galaxy collection install community.postgresql
ansible-playbook ansible/setup_db.yml
```

### Step 5: Create Jenkins Pipeline

Create `Jenkinsfile`:
```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'myflaskapp'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            agent {
                docker {
                    image 'python:3.11-slim'
                }
            }
            steps {
                dir('app') {
                    sh '''
                        pip install -r requirements.txt
                        pip install pytest
                        python -c "from app import app; print('Import OK')"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Configure with Ansible') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook setup_db.yml'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    sleep 10
                    curl -f http://localhost:8080/ || exit 1
                    echo "Deployment successful!"
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline completed with status: ${currentBuild.result}"
        }
    }
}
```

---

## Scenario 2: Kubernetes Deployment with GitOps

Deploy the same app to Kubernetes using GitOps principles.

### Step 1: Kubernetes Manifests

Create `k8s/base/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myflaskapp
  labels:
    app: myflaskapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myflaskapp
  template:
    metadata:
      labels:
        app: myflaskapp
    spec:
      containers:
        - name: app
          image: myflaskapp:latest
          ports:
            - containerPort: 5000
          env:
            - name: DB_HOST
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: db_host
            - name: DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: db_name
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
          resources:
            limits:
              memory: "256Mi"
              cpu: "500m"
            requests:
              memory: "128Mi"
              cpu: "250m"
          readinessProbe:
            httpGet:
              path: /
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: 5000
            initialDelaySeconds: 15
            periodSeconds: 20
```

Create `k8s/base/service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myflaskapp-service
spec:
  type: ClusterIP
  selector:
    app: myflaskapp
  ports:
    - port: 80
      targetPort: 5000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myflaskapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: myapp.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myflaskapp-service
                port:
                  number: 80
```

Create `k8s/base/configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  db_host: "postgres-service"
  db_name: "myapp"
```

Create `k8s/base/secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  username: appuser
  password: secretpassword
```

Create `k8s/base/postgres.yaml`:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
            - name: POSTGRES_DB
              value: myapp
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: postgres-storage
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
```

### Step 2: Terraform for Kubernetes

Create `terraform/kubernetes.tf`:
```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "myapp" {
  metadata {
    name = "myapp"
    labels = {
      environment = "development"
      managed-by  = "terraform"
    }
  }
}

# Apply all manifests from k8s/base directory
resource "kubernetes_manifest" "app_manifests" {
  for_each = fileset("${path.module}/../k8s/base", "*.yaml")

  manifest = yamldecode(file("${path.module}/../k8s/base/${each.value}"))
}
```

### Step 3: ArgoCD Application

Create `argocd/myapp.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myflaskapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/youruser/myapp.git
    targetRevision: HEAD
    path: k8s/base
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Scenario 3: Ansible Configuring Linux VMs for Docker Swarm

Deploy a Docker Swarm cluster using Ansible.

### Inventory

Create `ansible/inventory/swarm.ini`:
```ini
[managers]
manager1 ansible_host=playground-vm

[workers]
worker1 ansible_host=worker-vm-1
worker2 ansible_host=worker-vm-2

[swarm:children]
managers
workers

[swarm:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3
```

### Playbook

Create `ansible/setup_swarm.yml`:
```yaml
---
- name: Install Docker on all nodes
  hosts: swarm
  become: yes

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install prerequisites
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
        state: present

    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable
        state: present

    - name: Install Docker
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
        state: present

    - name: Start Docker service
      service:
        name: docker
        state: started
        enabled: yes

- name: Initialize Swarm on manager
  hosts: managers
  become: yes

  tasks:
    - name: Check if Swarm is initialized
      command: docker info --format '{{ "{{" }}.Swarm.LocalNodeState{{ "}}" }}'
      register: swarm_status
      changed_when: false

    - name: Initialize Docker Swarm
      command: docker swarm init --advertise-addr {{ ansible_host }}
      when: swarm_status.stdout != "active"
      register: swarm_init

    - name: Get worker join token
      command: docker swarm join-token -q worker
      register: worker_token
      changed_when: false

    - name: Store worker token
      set_fact:
        swarm_worker_token: "{{ worker_token.stdout }}"

- name: Join workers to Swarm
  hosts: workers
  become: yes

  tasks:
    - name: Check if node is in Swarm
      command: docker info --format '{{ "{{" }}.Swarm.LocalNodeState{{ "}}" }}'
      register: swarm_status
      changed_when: false

    - name: Join Swarm as worker
      command: >
        docker swarm join
        --token {{ hostvars[groups['managers'][0]]['swarm_worker_token'] }}
        {{ hostvars[groups['managers'][0]]['ansible_host'] }}:2377
      when: swarm_status.stdout != "active"

- name: Deploy application stack
  hosts: managers
  become: yes

  tasks:
    - name: Copy docker-compose file
      copy:
        src: files/docker-compose.yml
        dest: /opt/myapp/docker-compose.yml

    - name: Deploy stack
      command: docker stack deploy -c /opt/myapp/docker-compose.yml myapp
```

---

## Scenario 4: Complete Monitoring Pipeline

How Prometheus, Grafana, and applications integrate.

### Application with Metrics

Update `app/app.py` to expose Prometheus metrics:
```python
from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

# Define metrics
REQUEST_COUNT = Counter(
    'app_requests_total',
    'Total app requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'app_request_latency_seconds',
    'Request latency in seconds',
    ['endpoint']
)

@app.before_request
def before_request():
    from flask import request, g
    g.start_time = time.time()

@app.after_request
def after_request(response):
    from flask import request, g
    latency = time.time() - g.start_time
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        status=response.status_code
    ).inc()
    REQUEST_LATENCY.labels(endpoint=request.path).observe(latency)
    return response

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/')
def index():
    return jsonify({"status": "healthy"})

@app.route('/slow')
def slow():
    time.sleep(2)  # Simulate slow endpoint
    return jsonify({"status": "slow but ok"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Prometheus Configuration

Update `prometheus.yml` to scrape the app:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'myflaskapp'
    static_configs:
      - targets: ['myapp-web:5000']
    metrics_path: /metrics

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### Grafana Dashboard (JSON)

```json
{
  "title": "Flask App Dashboard",
  "panels": [
    {
      "title": "Request Rate",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(app_requests_total[5m])",
          "legendFormat": "{{ "{{" }}method{{ "}}" }} {{ "{{" }}endpoint{{ "}}" }}"
        }
      ]
    },
    {
      "title": "Request Latency (p95)",
      "type": "graph",
      "targets": [
        {
          "expr": "histogram_quantile(0.95, rate(app_request_latency_seconds_bucket[5m]))",
          "legendFormat": "{{ "{{" }}endpoint{{ "}}" }}"
        }
      ]
    },
    {
      "title": "Error Rate",
      "type": "singlestat",
      "targets": [
        {
          "expr": "sum(rate(app_requests_total{status=~\"5..\"}[5m])) / sum(rate(app_requests_total[5m])) * 100"
        }
      ]
    }
  ]
}
```

---

## Scenario 5: Secrets Flow with Vault

How secrets flow from Vault to applications.

### Setup Vault Secret

```bash
# Enable KV secrets
vault secrets enable -path=myapp kv-v2

# Store database credentials
vault kv put myapp/database \
    username=appuser \
    password=secretpassword \
    host=postgres-service \
    name=myapp
```

### Terraform Reading from Vault

```hcl
provider "vault" {
  address = "http://vault:8200"
}

data "vault_kv_secret_v2" "db_creds" {
  mount = "myapp"
  name  = "database"
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = "myapp"
  }

  data = {
    username = data.vault_kv_secret_v2.db_creds.data["username"]
    password = data.vault_kv_secret_v2.db_creds.data["password"]
  }
}
```

### Ansible Reading from Vault

```yaml
- name: Deploy with Vault secrets
  hosts: all
  vars:
    vault_addr: "http://vault:8200"
    vault_token: "{{ lookup('env', 'VAULT_TOKEN') }}"

  tasks:
    - name: Read secret from Vault
      community.hashi_vault.vault_kv2_get:
        url: "{{ vault_addr }}"
        token: "{{ vault_token }}"
        path: myapp/database
      register: db_secret

    - name: Configure application
      template:
        src: app_config.j2
        dest: /etc/myapp/config.yaml
      vars:
        db_user: "{{ db_secret.secret.username }}"
        db_pass: "{{ db_secret.secret.password }}"
```

---

## Summary: Tool Relationships

| Tool | Creates/Manages | Consumes From | Outputs To |
|------|-----------------|---------------|------------|
| **Git** | Source code, configs | Developers | Jenkins, ArgoCD |
| **Jenkins** | Builds, tests, deploys | Git | Docker, Terraform, Ansible |
| **Docker** | Container images | Source code | Registry, K8s, Terraform |
| **Terraform** | Infrastructure | Provider APIs | K8s, Docker, Cloud |
| **Ansible** | Server configs | Inventory, Vault | Linux VMs, containers |
| **Kubernetes** | Container orchestration | Docker images | Running apps |
| **Prometheus** | Metrics | App endpoints | Grafana, Alertmanager |
| **Vault** | Secrets | Admin | Terraform, Ansible, Apps |
| **ArgoCD** | K8s deployments | Git repos | Kubernetes |
