# Kubernetes In-Depth Theory

## Container Orchestration Fundamentals

### Why Kubernetes?

Without orchestration, you face:
- **No automatic recovery** - Container crashes mean manual restarts
- **No scaling** - Manual container management per host
- **No service discovery** - Hardcoded IPs and ports
- **No load balancing** - Single points of failure
- **No rolling updates** - Downtime during deployments

### Kubernetes Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                              KUBERNETES CLUSTER                                 │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         CONTROL PLANE                                    │   │
│  │                                                                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │  API Server  │  │  Controller  │  │  Scheduler   │  │    etcd    │  │   │
│  │  │              │  │   Manager    │  │              │  │ (database) │  │   │
│  │  │ - Auth       │  │              │  │              │  │            │  │   │
│  │  │ - Validation │  │ - Deployment │  │ - Pod        │  │ - Cluster  │  │   │
│  │  │ - REST API   │  │ - ReplicaSet │  │   Placement  │  │   State    │  │   │
│  │  │              │  │ - Node       │  │ - Resource   │  │            │  │   │
│  │  │              │  │              │  │   Aware      │  │            │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │   │
│  │                                                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                          │
│                                      │ API                                      │
│                                      ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           WORKER NODES                                   │   │
│  │                                                                          │   │
│  │  ┌─────────────────────────────┐   ┌─────────────────────────────┐      │   │
│  │  │          Node 1             │   │          Node 2             │      │   │
│  │  │                             │   │                             │      │   │
│  │  │  ┌────────┐  ┌────────┐    │   │  ┌────────┐  ┌────────┐    │      │   │
│  │  │  │  Pod   │  │  Pod   │    │   │  │  Pod   │  │  Pod   │    │      │   │
│  │  │  │ ┌────┐ │  │ ┌────┐ │    │   │  │ ┌────┐ │  │ ┌────┐ │    │      │   │
│  │  │  │ │ C1 │ │  │ │ C1 │ │    │   │  │ │ C1 │ │  │ │ C1 │ │    │      │   │
│  │  │  │ └────┘ │  │ │ C2 │ │    │   │  │ └────┘ │  │ └────┘ │    │      │   │
│  │  │  └────────┘  │ └────┘ │    │   │  └────────┘  └────────┘    │      │   │
│  │  │              └────────┘    │   │                             │      │   │
│  │  │  ┌─────────────────────┐   │   │  ┌─────────────────────┐   │      │   │
│  │  │  │      kubelet        │   │   │  │      kubelet        │   │      │   │
│  │  │  │  (node agent)       │   │   │  │  (node agent)       │   │      │   │
│  │  │  └─────────────────────┘   │   │  └─────────────────────┘   │      │   │
│  │  │  ┌─────────────────────┐   │   │  ┌─────────────────────┐   │      │   │
│  │  │  │    kube-proxy       │   │   │  │    kube-proxy       │   │      │   │
│  │  │  │  (networking)       │   │   │  │  (networking)       │   │      │   │
│  │  │  └─────────────────────┘   │   │  └─────────────────────┘   │      │   │
│  │  └─────────────────────────┘   └─────────────────────────────┘      │   │
│  │                                                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└────────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Role |
|-----------|------|
| **API Server** | Frontend to the cluster; all interactions go through it |
| **etcd** | Distributed key-value store holding all cluster data |
| **Scheduler** | Assigns pods to nodes based on resources and constraints |
| **Controller Manager** | Runs controllers that maintain desired state |
| **kubelet** | Agent on each node; manages pods and containers |
| **kube-proxy** | Manages network rules for pod communication |

---

## Kubernetes Objects Deep Dive

### Pods

A **Pod** is the smallest deployable unit, containing one or more containers.

**Why multiple containers in a pod?**
- Sidecar pattern (logging, monitoring)
- Ambassador pattern (proxy)
- Adapter pattern (data transformation)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  labels:
    app: web
    version: v1
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
      resources:
        requests:
          memory: "64Mi"
          cpu: "100m"
        limits:
          memory: "128Mi"
          cpu: "250m"
      livenessProbe:
        httpGet:
          path: /healthz
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
      readinessProbe:
        httpGet:
          path: /ready
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 5
      volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d

    - name: log-forwarder  # Sidecar
      image: fluent-bit:latest
      volumeMounts:
        - name: logs
          mountPath: /var/log/nginx

  volumes:
    - name: config
      configMap:
        name: nginx-config
    - name: logs
      emptyDir: {}
```

### Deployments

**Deployments** manage ReplicaSets which manage Pods. They provide:
- Declarative updates
- Rolling updates and rollbacks
- Scaling

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods over desired during update
      maxUnavailable: 0  # Min pods available during update
  template:
    metadata:
      labels:
        app: webapp
        version: v1
    spec:
      containers:
        - name: webapp
          image: myapp:v1
          ports:
            - containerPort: 8080
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

**Deployment commands:**
```bash
# Create/update deployment
kubectl apply -f deployment.yaml

# View rollout status
kubectl rollout status deployment/webapp

# View rollout history
kubectl rollout history deployment/webapp

# Rollback to previous version
kubectl rollout undo deployment/webapp

# Rollback to specific revision
kubectl rollout undo deployment/webapp --to-revision=2

# Scale deployment
kubectl scale deployment/webapp --replicas=5

# Update image
kubectl set image deployment/webapp webapp=myapp:v2
```

### Services (Networking)

**Services** provide stable endpoints for accessing pods.

```
┌─────────────────────────────────────────────────────────────────────┐
│                      SERVICE TYPES                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ClusterIP (default)                                                │
│  ┌─────────────┐        ┌─────────────────────┐                     │
│  │  Service    │◄──────►│   Pods (internal)   │                     │
│  │ 10.0.0.50   │        │                     │                     │
│  └─────────────┘        └─────────────────────┘                     │
│  Only accessible within cluster                                      │
│                                                                      │
│  NodePort                                                            │
│  ┌─────────────┐        ┌─────────────┐        ┌─────────────────┐ │
│  │  External   │───────►│  Node:30080 │───────►│      Pods       │ │
│  │   Traffic   │        │             │        │                 │ │
│  └─────────────┘        └─────────────┘        └─────────────────┘ │
│  Exposes on all nodes' IPs                                          │
│                                                                      │
│  LoadBalancer (cloud)                                               │
│  ┌─────────────┐        ┌─────────────┐        ┌─────────────────┐ │
│  │  Cloud LB   │───────►│   Service   │───────►│      Pods       │ │
│  │  (public)   │        │             │        │                 │ │
│  └─────────────┘        └─────────────┘        └─────────────────┘ │
│  Cloud provider provisions a load balancer                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

```yaml
# ClusterIP - internal access
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8080
---
# NodePort - external access on node IP
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080  # Optional, defaults to 30000-32767
---
# LoadBalancer - cloud load balancer
apiVersion: v1
kind: Service
metadata:
  name: public-api
spec:
  type: LoadBalancer
  selector:
    app: api
  ports:
    - port: 443
      targetPort: 8443
```

### Ingress

**Ingress** manages external HTTP/HTTPS access to services.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - myapp.example.com
      secretName: tls-secret
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

---

## ConfigMaps and Secrets

### ConfigMaps

Store non-sensitive configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Simple key-value
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  
  # File content
  app.properties: |
    database.host=postgres
    database.port=5432
    cache.enabled=true
```

**Using ConfigMaps:**
```yaml
spec:
  containers:
    - name: app
      # As environment variables
      envFrom:
        - configMapRef:
            name: app-config
      # Or individual variables
      env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL
      # As mounted files
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
```

### Secrets

Store sensitive data (base64 encoded, not encrypted by default):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:  # Plain text (K8s encodes automatically)
  username: admin
  password: supersecret123
  connection-string: "postgres://admin:supersecret123@db:5432/myapp"
---
# For Docker registry authentication
apiVersion: v1
kind: Secret
metadata:
  name: registry-creds
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

**Using Secrets:**
```yaml
spec:
  imagePullSecrets:
    - name: registry-creds
  containers:
    - name: app
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
      volumeMounts:
        - name: secrets
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secrets
      secret:
        secretName: db-credentials
```

---

## Persistent Storage

### PersistentVolume and PersistentVolumeClaim

```yaml
# PersistentVolume (cluster resource, created by admin)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:  # For local development
    path: /data/postgres
---
# PersistentVolumeClaim (pod requests storage)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
---
# Using in a Pod
apiVersion: v1
kind: Pod
metadata:
  name: postgres
spec:
  containers:
    - name: postgres
      image: postgres:15
      volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: postgres-pvc
```

---

## Complete Application Example

### Full Stack Deployment

```yaml
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
---
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: myapp
data:
  APP_ENV: production
  LOG_LEVEL: info
---
# Secret
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: myapp
stringData:
  POSTGRES_USER: myapp
  POSTGRES_PASSWORD: secretpassword
  DATABASE_URL: postgres://myapp:secretpassword@postgres:5432/myapp
---
# PostgreSQL StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: myapp
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
          envFrom:
            - secretRef:
                name: db-secret
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 5Gi
---
# PostgreSQL Service
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: myapp
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
---
# Application Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
        - name: webapp
          image: myapp:latest
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: db-secret
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 15
---
# Application Service
apiVersion: v1
kind: Service
metadata:
  name: webapp
  namespace: myapp
spec:
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 8080
---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: myapp
spec:
  rules:
    - host: myapp.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: webapp
                port:
                  number: 80
```

**Deploy:**
```bash
kubectl apply -f full-app.yaml

# Verify
kubectl get all -n myapp
kubectl logs -f deployment/webapp -n myapp

# Access (add to /etc/hosts: 127.0.0.1 myapp.local)
curl http://myapp.local
```
