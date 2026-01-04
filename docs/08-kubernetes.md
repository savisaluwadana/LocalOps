# Kubernetes Fundamentals

## What is Kubernetes?

Kubernetes (K8s) is a **container orchestration platform** that automates deployment, scaling, and management of containerized applications.

### Why Kubernetes?

| Challenge | K8s Solution |
|-----------|--------------|
| Container crashes | Auto-restarts containers |
| Traffic spikes | Auto-scaling |
| Zero-downtime deploys | Rolling updates |
| Service discovery | Built-in DNS |
| Load balancing | Automatic distribution |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                        │
├─────────────────────────────────────────────────────────────┤
│  Control Plane                                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐   │
│  │API Server│ │Scheduler │ │Controller│ │     etcd      │   │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  Worker Nodes                                                │
│  ┌─────────────────────────┐  ┌─────────────────────────┐   │
│  │  Node 1                 │  │  Node 2                 │   │
│  │  ┌─────┐ ┌─────┐       │  │  ┌─────┐ ┌─────┐       │   │
│  │  │ Pod │ │ Pod │       │  │  │ Pod │ │ Pod │       │   │
│  │  └─────┘ └─────┘       │  │  └─────┘ └─────┘       │   │
│  │  kubelet, kube-proxy    │  │  kubelet, kube-proxy    │   │
│  └─────────────────────────┘  └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### 1. Pods
The smallest deployable unit. Contains one or more containers.

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
```

### 2. Deployments
Manages replicas of pods with rolling updates.

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
```

### 3. Services
Expose pods to network traffic.

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer  # or ClusterIP, NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

### 4. ConfigMaps & Secrets

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "db.example.com"
  LOG_LEVEL: "info"
---
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 encoded
```

Use in a pod:
```yaml
spec:
  containers:
    - name: app
      envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
```

---

## Hands-On: Local Kubernetes with OrbStack

OrbStack includes a built-in Kubernetes cluster.

### Enable Kubernetes

1. Open OrbStack preferences
2. Enable Kubernetes
3. Verify: `kubectl cluster-info`

### Exercise 1: Deploy Nginx

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:alpine --replicas=3

# Expose as service
kubectl expose deployment nginx --port=80 --type=NodePort

# Check status
kubectl get pods
kubectl get services

# Get the NodePort
kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}'

# Access it
curl localhost:<nodeport>
```

### Exercise 2: Deploy from YAML

Create `playground/kubernetes/nginx-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          resources:
            limits:
              memory: "128Mi"
              cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

Apply and verify:
```bash
kubectl apply -f nginx-app.yaml
kubectl get all
kubectl port-forward svc/web-service 8080:80
# Visit http://localhost:8080
```

---

## Essential kubectl Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Workloads
kubectl get pods
kubectl get deployments
kubectl get services

# Details
kubectl describe pod <name>
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # follow

# Interactive
kubectl exec -it <pod-name> -- /bin/sh

# Apply/Delete
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml

# Scaling
kubectl scale deployment <name> --replicas=5

# Cleanup
kubectl delete pod <name>
kubectl delete deployment <name>
```

---

## Helm (Package Manager)

Helm manages Kubernetes applications with charts.

```bash
# Install Helm
brew install helm

# Add a repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Search for charts
helm search repo nginx

# Install a chart
helm install my-nginx bitnami/nginx

# List releases
helm list

# Uninstall
helm uninstall my-nginx
```

---

## Further Learning

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Play with K8s](https://labs.play-with-k8s.com/)
- Certification: CKA (Certified Kubernetes Administrator)
