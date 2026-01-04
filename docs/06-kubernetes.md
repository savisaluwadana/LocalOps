# Kubernetes Complete Theory Guide

## Table of Contents

1. [What is Kubernetes?](#what-is-kubernetes)
2. [Why Kubernetes?](#why-kubernetes)
3. [Architecture Deep Dive](#architecture-deep-dive)
4. [Core Concepts Explained](#core-concepts-explained)
5. [Workload Resources](#workload-resources)
6. [Services and Networking](#services-and-networking)
7. [Storage](#storage)
8. [Configuration and Secrets](#configuration-and-secrets)
9. [Security](#security)
10. [Scheduling and Resource Management](#scheduling-and-resource-management)
11. [Observability](#observability)
12. [Best Practices](#best-practices)

---

## What is Kubernetes?

### Definition

Kubernetes (K8s) is an open-source **container orchestration platform** that automates deploying, scaling, and managing containerized applications.

The name "Kubernetes" comes from Greek, meaning "helmsman" or "pilot" — the one who steers the ship.

### The Journey

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          EVOLUTION OF APPLICATION DEPLOYMENT                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   2000s: Physical Servers                                                           │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  • One app per server                                                        │   │
│   │  • Expensive hardware                                                        │   │
│   │  • Wasted resources                                                          │   │
│   │  • Slow provisioning (weeks)                                                │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         ↓                                            │
│   2010s: Virtual Machines                                                           │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  • Multiple VMs per server                                                   │   │
│   │  • Better resource utilization                                               │   │
│   │  • Faster provisioning (minutes)                                            │   │
│   │  • Still heavy (each VM has full OS)                                        │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         ↓                                            │
│   2014+: Containers (Docker)                                                        │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  • Lightweight (share OS kernel)                                            │   │
│   │  • Instant startup (seconds)                                                │   │
│   │  • Consistent environments                                                   │   │
│   │  • But... how to manage 1000s of containers?                                │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         ↓                                            │
│   2015+: Kubernetes                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  • Orchestrates container lifecycle                                          │   │
│   │  • Automated scaling and healing                                            │   │
│   │  • Declarative configuration                                                 │   │
│   │  • Built-in service discovery and load balancing                           │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Key Terminology

Before diving deep, let's establish vocabulary:

| Term | Definition | Analogy |
|------|------------|---------|
| **Cluster** | A set of machines running Kubernetes | A shipping company |
| **Node** | A single machine in the cluster | A ship |
| **Pod** | Smallest deployable unit (one or more containers) | A shipping container |
| **Deployment** | Manages pods and ensures desired state | Shipping order |
| **Service** | Exposes pods to network traffic | Port/dock for ships |
| **Namespace** | Virtual cluster within a cluster | Different departments |
| **kubectl** | Command-line tool to interact with cluster | Your radio to the ships |

---

## Why Kubernetes?

### The Problems Kubernetes Solves

**1. "My container crashed at 3 AM"**

Without Kubernetes:
- You get a PagerDuty alert
- SSH into the server
- Manually restart the container
- Hope it doesn't happen again

With Kubernetes:
- Kubernetes automatically detects the crash
- Restarts the container
- You sleep peacefully

**2. "Traffic spike is killing our servers"**

Without Kubernetes:
- Manually spin up more containers
- Configure load balancer
- Remember to scale down later (or forget and waste money)

With Kubernetes:
- Auto-scales based on CPU/memory/custom metrics
- Automatically adds containers during spike
- Scales down when traffic normalizes

**3. "We need zero-downtime deployments"**

Without Kubernetes:
- Complex scripts to gradually replace containers
- Manual health checks
- Hope nothing goes wrong during deploy

With Kubernetes:
- Rolling updates are built-in
- Health checks ensure new version works
- Automatic rollback if something fails

### Core Capabilities

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES CAPABILITIES                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   SELF-HEALING                                                                       │
│   ├── Restarts failed containers                                                    │
│   ├── Replaces unresponsive containers                                              │
│   ├── Kills containers that fail health checks                                      │
│   └── Reschedules pods when nodes fail                                              │
│                                                                                      │
│   HORIZONTAL SCALING                                                                 │
│   ├── Scale up/down with a command                                                  │
│   ├── Auto-scale based on metrics                                                   │
│   └── Scale to zero (serverless patterns)                                           │
│                                                                                      │
│   AUTOMATED ROLLOUTS/ROLLBACKS                                                       │
│   ├── Gradually roll out changes                                                    │
│   ├── Monitor application health                                                    │
│   └── Automatically roll back on failure                                            │
│                                                                                      │
│   SERVICE DISCOVERY & LOAD BALANCING                                                 │
│   ├── DNS-based service discovery                                                   │
│   ├── Built-in load balancing                                                       │
│   └── Automatic endpoint updates                                                    │
│                                                                                      │
│   SECRET & CONFIGURATION MANAGEMENT                                                  │
│   ├── Store and manage sensitive data                                               │
│   ├── Update configurations without rebuilding                                      │
│   └── Mount configs as files or environment variables                              │
│                                                                                      │
│   STORAGE ORCHESTRATION                                                              │
│   ├── Automatically mount storage                                                   │
│   ├── Support for cloud, NFS, local storage                                         │
│   └── Dynamic provisioning                                                          │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Architecture Deep Dive

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES CLUSTER                                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                           CONTROL PLANE                                      │   │
│   │                    (The brain - manages the cluster)                         │   │
│   │                                                                              │   │
│   │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                │   │
│   │  │  API Server    │  │   Scheduler    │  │  Controller    │                │   │
│   │  │                │  │                │  │   Manager      │                │   │
│   │  │  Entry point   │  │  Assigns pods  │  │  Maintains     │                │   │
│   │  │  for all API   │  │  to nodes      │  │  desired state │                │   │
│   │  └───────┬────────┘  └────────────────┘  └────────────────┘                │   │
│   │          │                                                                   │   │
│   │  ┌───────▼────────┐  ┌────────────────────────────────────┐                │   │
│   │  │     etcd       │  │  Cloud Controller Manager         │                │   │
│   │  │                │  │  (optional, for cloud providers)  │                │   │
│   │  │  Key-value     │  └────────────────────────────────────┘                │   │
│   │  │  store (brain  │                                                         │   │
│   │  │  storage)      │                                                         │   │
│   │  └────────────────┘                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                       │                                              │
│                                       │ (kubectl, API calls)                        │
│                                       ▼                                              │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                           WORKER NODES                                       │   │
│   │                    (The workers - run your applications)                     │   │
│   │                                                                              │   │
│   │  Node 1                    Node 2                    Node 3                 │   │
│   │  ┌────────────────┐       ┌────────────────┐       ┌────────────────┐      │   │
│   │  │ kubelet        │       │ kubelet        │       │ kubelet        │      │   │
│   │  │ kube-proxy     │       │ kube-proxy     │       │ kube-proxy     │      │   │
│   │  │ Container RT   │       │ Container RT   │       │ Container RT   │      │   │
│   │  │                │       │                │       │                │      │   │
│   │  │ ┌────┐ ┌────┐ │       │ ┌────┐ ┌────┐ │       │ ┌────┐         │      │   │
│   │  │ │Pod1│ │Pod2│ │       │ │Pod3│ │Pod4│ │       │ │Pod5│         │      │   │
│   │  │ └────┘ └────┘ │       │ └────┘ └────┘ │       │ └────┘         │      │   │
│   │  └────────────────┘       └────────────────┘       └────────────────┘      │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Control Plane Components Explained

**1. API Server (kube-apiserver)**

The API server is the front door to Kubernetes. Every interaction—whether from kubectl, the dashboard, or other components—goes through the API server.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           API SERVER                                                 │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   What it does:                                                                      │
│   • Exposes the Kubernetes API (REST)                                               │
│   • Authenticates and authorizes requests                                           │
│   • Validates API objects (is this a valid Pod spec?)                               │
│   • Serves as the cluster's gateway                                                 │
│                                                                                      │
│   Example flow when you run: kubectl create deployment nginx --image=nginx          │
│                                                                                      │
│   1. kubectl sends HTTP POST to API server                                          │
│   2. API server authenticates you (who are you?)                                    │
│   3. API server authorizes you (can you create deployments?)                        │
│   4. Admission controllers validate/mutate request                                  │
│   5. Object stored in etcd                                                          │
│   6. Controllers notified of new object                                             │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**2. etcd**

etcd is a distributed key-value store that holds the entire state of your cluster.

```
Key-Value Examples:

/registry/pods/default/nginx-abc123 → {Pod specification JSON}
/registry/deployments/default/nginx → {Deployment spec JSON}
/registry/services/default/nginx → {Service spec JSON}
/registry/configmaps/default/app-config → {ConfigMap data}
```

**Important etcd facts:**
- If etcd is lost without backup, your cluster is gone
- All other components can be recreated from etcd
- Production clusters run 3-5 etcd nodes for high availability
- etcd uses the Raft consensus algorithm

**3. Scheduler (kube-scheduler)**

The scheduler's job is simple: find the best node for each unscheduled pod.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           SCHEDULER DECISION PROCESS                                 │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   New Pod: nginx (needs 500m CPU, 512Mi memory)                                     │
│                                                                                      │
│   Step 1: FILTERING (find nodes that CAN run the pod)                               │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │ Node A (4 CPU, 8Gi) ✓ Has enough resources                                  │   │
│   │ Node B (1 CPU, 2Gi) ✓ Has enough resources                                  │   │
│   │ Node C (full)       ✗ Not enough resources                                  │   │
│   │ Node D (tainted)    ✗ Pod doesn't tolerate taint                            │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   Step 2: SCORING (find the BEST node among candidates)                             │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │ Node A: Score 85                                                             │   │
│   │   - Resource balance: +30                                                    │   │
│   │   - Spread constraint: +25                                                   │   │
│   │   - Image already present: +20                                               │   │
│   │   - Node affinity match: +10                                                 │   │
│   │                                                                              │   │
│   │ Node B: Score 60                                                             │   │
│   │   - Resource balance: +40                                                    │   │
│   │   - Spread constraint: +20                                                   │   │
│   │   - Image not present: 0                                                     │   │
│   │   - No affinity: 0                                                           │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   Result: Pod scheduled to Node A (highest score)                                   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**4. Controller Manager**

Controllers are control loops that watch the cluster state and make changes to move the actual state toward the desired state.

```
Desired State: 3 nginx replicas
Actual State:  2 nginx pods running

Controller Action: Create 1 more nginx pod
```

**Built-in Controllers:**
| Controller | Watches | Actions |
|------------|---------|---------|
| Deployment | Deployments | Creates/updates ReplicaSets |
| ReplicaSet | ReplicaSets | Creates/deletes Pods |
| Node | Nodes | Handles node failures, assigns CIDRs |
| Job | Jobs | Creates Pods, tracks completion |
| Service | Services/Endpoints | Updates endpoint lists |

### Worker Node Components

**1. kubelet**

The kubelet is an agent running on every node. It's responsible for making sure containers run in pods.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           KUBELET RESPONSIBILITIES                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   • Registers node with the cluster                                                 │
│   • Watches API server for pod assignments                                          │
│   • Coordinates with container runtime (containerd)                                 │
│   • Mounts volumes                                                                  │
│   • Reports node and pod status                                                     │
│   • Runs liveness and readiness probes                                              │
│                                                                                      │
│   When API server says "run this pod on your node":                                 │
│   1. kubelet pulls image (if not cached)                                           │
│   2. Creates pod sandbox (network namespace, etc.)                                 │
│   3. Starts containers                                                              │
│   4. Sets up volumes                                                                │
│   5. Continuously monitors pod health                                               │
│   6. Reports status back to API server                                              │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**2. kube-proxy**

kube-proxy maintains network rules on nodes, implementing the Service concept.

```
When you create a Service:
  Service: nginx-svc (ClusterIP: 10.96.0.50:80)
    → Pod1: 10.244.1.10:8080
    → Pod2: 10.244.2.15:8080
    → Pod3: 10.244.3.20:8080

kube-proxy creates iptables/IPVS rules:
  Traffic to 10.96.0.50:80 → Round-robin to pod IPs
```

**3. Container Runtime**

The container runtime actually runs containers. Modern Kubernetes uses containerd, which implements the Container Runtime Interface (CRI).

```
Kubernetes (CRI) → containerd → runc → Linux containers
```

---

## Core Concepts Explained

### Pods

A **Pod** is the smallest deployable unit in Kubernetes. It represents one or more containers that share:
- Network namespace (same IP address)
- Storage volumes
- Lifecycle (start and stop together)

**Why multiple containers per pod?**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           SINGLE-CONTAINER POD (Most Common)                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   ┌───────────────────────────────────────────────────────────┐                     │
│   │                          POD                              │                     │
│   │   ┌─────────────────────────────────────────────────────┐ │                     │
│   │   │              Main Application Container              │ │                     │
│   │   │                    (nginx, api, etc.)                │ │                     │
│   │   └─────────────────────────────────────────────────────┘ │                     │
│   │   IP: 10.244.1.5                                          │                     │
│   └───────────────────────────────────────────────────────────┘                     │
│                                                                                      │
│   This is the most common pattern. One container per pod.                           │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           MULTI-CONTAINER POD (Sidecar Pattern)                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   ┌───────────────────────────────────────────────────────────┐                     │
│   │                          POD                              │                     │
│   │   ┌───────────────────────┐  ┌────────────────────────┐ │                     │
│   │   │  Main App Container   │  │   Sidecar Container     │ │                     │
│   │   │  (nginx)              │─▶│   (log-shipper)         │ │                     │
│   │   └───────────────────────┘  └────────────────────────┘ │                     │
│   │              │                           │               │                     │
│   │              └─────────────┬─────────────┘               │                     │
│   │                   Shared Volume (/logs)                   │                     │
│   │   IP: 10.244.1.6                                          │                     │
│   └───────────────────────────────────────────────────────────┘                     │
│                                                                                      │
│   Use cases:                                                                         │
│   • Sidecar: logging, monitoring agents                                             │
│   • Ambassador: proxy to external services                                          │
│   • Adapter: transform output format                                                │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Pod YAML Example:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    environment: production
spec:
  containers:
    - name: nginx
      image: nginx:1.25
      ports:
        - containerPort: 80
      resources:
        requests:
          memory: "64Mi"
          cpu: "250m"
        limits:
          memory: "128Mi"
          cpu: "500m"
      livenessProbe:
        httpGet:
          path: /health
          port: 80
        initialDelaySeconds: 10
        periodSeconds: 5
```

### Labels and Selectors

**Labels** are key-value pairs attached to objects. They're how you organize and select resources.

```yaml
# Adding labels to a Pod
metadata:
  labels:
    app: nginx
    environment: production
    tier: frontend
    version: v1.2.3
```

**Selectors** find objects by their labels:

```yaml
# Equality-based selector
selector:
  matchLabels:
    app: nginx
    environment: production

# Set-based selector
selector:
  matchExpressions:
    - key: environment
      operator: In
      values: [production, staging]
    - key: tier
      operator: NotIn
      values: [backend]
```

**Why Labels Matter:**

```
Without labels, how do you:
• Tell Service which Pods to route traffic to?
• Tell Deployment which Pods it manages?
• Select all production database Pods for maintenance?

Labels enable loose coupling between resources.
```

### Namespaces

Namespaces provide virtual clusters within a physical cluster. Think of them as folders for your resources.

**Default Namespaces:**

| Namespace | Purpose |
|-----------|---------|
| `default` | Where objects go if no namespace specified |
| `kube-system` | Kubernetes system components (DNS, proxy, etc.) |
| `kube-public` | Publicly accessible data (cluster info) |
| `kube-node-lease` | Node heartbeat data |

**Use Cases:**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           NAMESPACE STRATEGIES                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   By Environment:                                                                    │
│   ├── namespace: development                                                         │
│   ├── namespace: staging                                                             │
│   └── namespace: production                                                          │
│                                                                                      │
│   By Team:                                                                           │
│   ├── namespace: team-frontend                                                       │
│   ├── namespace: team-backend                                                        │
│   └── namespace: team-data                                                           │
│                                                                                      │
│   By Application:                                                                    │
│   ├── namespace: ecommerce                                                           │
│   ├── namespace: payments                                                            │
│   └── namespace: analytics                                                           │
│                                                                                      │
│   Namespaces provide:                                                                │
│   • Resource quotas per namespace                                                   │
│   • Network policies per namespace                                                  │
│   • RBAC scoped to namespace                                                        │
│   • Resource name isolation                                                         │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Workload Resources

### Deployments

A **Deployment** declares the desired state for Pods and ReplicaSets. It's the most common way to run applications.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DEPLOYMENT HIERARCHY                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Deployment                                                                         │
│   └── "I want 3 replicas of nginx:1.25"                                             │
│                                                                                      │
│       ├── ReplicaSet (managed by Deployment)                                        │
│       │   └── "Keep exactly 3 pods running"                                         │
│       │                                                                              │
│       │       ├── Pod 1 (nginx:1.25)                                                │
│       │       ├── Pod 2 (nginx:1.25)                                                │
│       │       └── Pod 3 (nginx:1.25)                                                │
│       │                                                                              │
│       └── On update, creates new ReplicaSet                                         │
│           └── ReplicaSet (new, nginx:1.26)                                          │
│               ├── Pod 1 (nginx:1.26)                                                │
│               ├── Pod 2 (nginx:1.26)                                                │
│               └── Pod 3 (nginx:1.26)                                                │
│                                                                                      │
│   Old ReplicaSet kept for rollback (scaled to 0)                                    │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Deployment YAML:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
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
          image: nginx:1.25
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 250m
              memory: 256Mi
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired during update
      maxUnavailable: 0   # Max pods unavailable during update
```

**Deployment Strategies:**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| RollingUpdate | Gradually replace pods | Zero-downtime, most apps |
| Recreate | Kill all pods, then create new | Database, stateful apps |

### StatefulSets

**StatefulSets** are for stateful applications that need:
- Stable, unique network identifiers
- Stable, persistent storage
- Ordered, graceful deployment and scaling

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           STATEFULSET vs DEPLOYMENT                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Deployment (stateless):                                                            │
│   ┌────────┐ ┌────────┐ ┌────────┐                                                  │
│   │nginx-  │ │nginx-  │ │nginx-  │   Random names                                   │
│   │abc123  │ │def456  │ │ghi789  │   Any order                                      │
│   └────────┘ └────────┘ └────────┘   Interchangeable                                │
│                                                                                      │
│   StatefulSet (stateful):                                                            │
│   ┌────────┐ ┌────────┐ ┌────────┐                                                  │
│   │ mysql- │ │ mysql- │ │ mysql- │   Predictable names: mysql-0, mysql-1, mysql-2  │
│   │   0    │ │   1    │ │   2    │   Created in order: 0 first, then 1, then 2     │
│   │        │ │        │ │        │   Deleted in reverse: 2, then 1, then 0         │
│   │  PVC0  │ │  PVC1  │ │  PVC2  │   Stable storage per pod                        │
│   └────────┘ └────────┘ └────────┘                                                  │
│                                                                                      │
│   Stable DNS: mysql-0.mysql-headless.default.svc.cluster.local                      │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### DaemonSets

A **DaemonSet** ensures that a copy of a Pod runs on all (or some) nodes.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      containers:
        - name: node-exporter
          image: prom/node-exporter
          ports:
            - containerPort: 9100
```

**Use Cases:**
- Log collectors (Fluentd, Filebeat)
- Monitoring agents (Prometheus node-exporter)
- Network plugins (Calico, Cilium)
- Storage daemons (Ceph, GlusterFS)

### Jobs and CronJobs

**Job:** Run a task to completion (once or with multiple completions).

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: backup-job
spec:
  completions: 1       # How many successful completions needed
  parallelism: 1       # How many pods can run in parallel
  backoffLimit: 3      # Retry limit
  activeDeadlineSeconds: 600  # Timeout
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: backup
          image: backup-tool
          command: ["./backup.sh"]
```

**CronJob:** Schedule Jobs to run periodically.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-backup
spec:
  schedule: "0 2 * * *"  # 2 AM every day
  concurrencyPolicy: Forbid  # Don't run if previous still running
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: backup
              image: backup-tool
```

---

## Services and Networking

### What is a Service?

A **Service** is an abstraction that defines a logical set of Pods and a policy to access them.

**Why Services?**
- Pods are ephemeral (they die and get new IPs)
- You need a stable way to reach pods
- You need load balancing

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           SERVICE ABSTRACTION                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Without Service:                         With Service:                            │
│                                                                                      │
│   Client                                   Client                                   │
│     │                                        │                                       │
│     │ Which IP? Pods keep changing!          │ nginx-service:80 (stable)            │
│     ▼                                        ▼                                       │
│   ┌──────┐ ┌──────┐ ┌──────┐             ┌─────────────────────────┐               │
│   │Pod   │ │Pod   │ │Pod   │             │        SERVICE          │               │
│   │IP: ? │ │IP: ? │ │IP: ?!│             │      (10.96.0.50)       │               │
│   └──────┘ └──────┘ └──────┘             └───────────┬─────────────┘               │
│                                                      │                              │
│   IPs change when pods restart!            ┌─────────┼─────────┐                   │
│                                            ▼         ▼         ▼                   │
│                                         ┌──────┐ ┌──────┐ ┌──────┐                │
│                                         │Pod A │ │Pod B │ │Pod C │                │
│                                         └──────┘ └──────┘ └──────┘                │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Service Types

| Type | Description | Use Case |
|------|-------------|----------|
| **ClusterIP** | Internal IP only | Default, internal services |
| **NodePort** | Expose on node IP | Dev/testing, simple exposure |
| **LoadBalancer** | Cloud load balancer | Production, internet-facing |
| **ExternalName** | DNS alias | Access external services |

```yaml
# ClusterIP (default) - internal only
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  type: ClusterIP
  selector:
    app: api
  ports:
    - port: 80        # Service port
      targetPort: 8080 # Container port

# NodePort - expose on node
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080   # Accessible at NodeIP:30080

# LoadBalancer - cloud LB
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

**Ingress** manages external HTTP/HTTPS access to services. It provides:
- Load balancing
- SSL/TLS termination
- Name-based virtual hosting
- Path-based routing

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           INGRESS ROUTING                                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Internet                                                                           │
│      │                                                                               │
│      ▼                                                                               │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                        INGRESS CONTROLLER                                    │   │
│   │                        (nginx, traefik, etc.)                               │   │
│   │                                                                              │   │
│   │   Rules:                                                                     │   │
│   │   app.example.com/api    → api-service:80                                   │   │
│   │   app.example.com/web    → web-service:80                                   │   │
│   │   blog.example.com       → blog-service:80                                  │   │
│   │                                                                              │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│            │                    │                    │                               │
│            ▼                    ▼                    ▼                               │
│     ┌───────────┐        ┌───────────┐        ┌───────────┐                        │
│     │api-service│        │web-service│        │blog-service│                        │
│     └───────────┘        └───────────┘        └───────────┘                        │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls-secret
  rules:
    - host: app.example.com
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
                name: web-service
                port:
                  number: 80
```

---

## Storage

### Storage Concepts

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES STORAGE HIERARCHY                               │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Pod                                                                                │
│   └── wants 10GB storage for database                                               │
│        │                                                                             │
│        ▼                                                                             │
│   PersistentVolumeClaim (PVC)                                                        │
│   └── "I need 10GB ReadWriteOnce storage"                                           │
│        │                                                                             │
│        ▼ (binds to matching PV)                                                     │
│   PersistentVolume (PV)                                                              │
│   └── "I have 10GB on AWS EBS"                                                      │
│        │                                                                             │
│        ▼                                                                             │
│   StorageClass                                                                       │
│   └── "I provision AWS EBS volumes"                                                 │
│        │                                                                             │
│        ▼                                                                             │
│   Actual Storage                                                                     │
│   └── AWS EBS volume, GCE Persistent Disk, NFS, etc.                                │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Volume Types

**Ephemeral:**
- `emptyDir` - Temporary directory, deleted with pod
- `configMap` / `secret` - Configuration/secrets as files

**Persistent:**
- `PersistentVolumeClaim` - Request for storage
- Cloud volumes (AWS EBS, GCP PD, Azure Disk)
- Network storage (NFS, Ceph, iSCSI)

### PersistentVolumeClaim Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  template:
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

## Configuration and Secrets

### ConfigMaps

Store non-confidential data as key-value pairs.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Simple key-value
  DATABASE_HOST: "postgres"
  LOG_LEVEL: "info"
  
  # Full file content
  config.json: |
    {
      "feature_flags": {
        "new_ui": true
      }
    }
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
      
      # Or specific keys
      env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_HOST
      
      # Or as files
      volumeMounts:
        - name: config
          mountPath: /etc/app/config.json
          subPath: config.json
  volumes:
    - name: config
      configMap:
        name: app-config
```

### Secrets

Store sensitive data (passwords, tokens, keys).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  # Values must be base64 encoded
  username: YWRtaW4=           # echo -n 'admin' | base64
  password: cGFzc3dvcmQxMjM=   # echo -n 'password123' | base64
```

**Secret Types:**

| Type | Use |
|------|-----|
| `Opaque` | Arbitrary user-defined data |
| `kubernetes.io/tls` | TLS certificate and key |
| `kubernetes.io/dockerconfigjson` | Docker registry auth |
| `kubernetes.io/service-account-token` | Service account tokens |

---

## Security

### RBAC (Role-Based Access Control)

Control who can do what in your cluster.

```yaml
# Role (namespace-scoped permissions)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]

---
# RoleBinding (grant Role to user/group)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
subjects:
  - kind: User
    name: developer@example.com
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Pod Security

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  
  containers:
    - name: app
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

---

## Best Practices

### Resource Management

Always define resource requests and limits:

```yaml
resources:
  requests:
    cpu: 100m      # 0.1 CPU cores
    memory: 128Mi  # 128 megabytes
  limits:
    cpu: 500m      # 0.5 CPU cores
    memory: 256Mi  # 256 megabytes
```

### Health Probes

Define probes for reliable operation:

```yaml
livenessProbe:      # Is the container alive?
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:     # Is the container ready for traffic?
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 3

startupProbe:       # For slow-starting containers
  httpGet:
    path: /health
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

### Labeling Convention

```yaml
labels:
  app.kubernetes.io/name: nginx
  app.kubernetes.io/version: "1.25"
  app.kubernetes.io/component: frontend
  app.kubernetes.io/part-of: myapp
  app.kubernetes.io/managed-by: helm
```

This comprehensive guide covers Kubernetes from fundamentals to advanced concepts with detailed explanations and practical examples.
