# Kubernetes Deep Dive Theory

A comprehensive guide to Kubernetes architecture, concepts, and advanced patterns.

## Table of Contents

1. [Kubernetes Architecture](#kubernetes-architecture)
2. [Core Concepts](#core-concepts)
3. [Workload Resources](#workload-resources)
4. [Networking](#networking)
5. [Storage](#storage)
6. [Security](#security)
7. [Advanced Patterns](#advanced-patterns)
8. [Operators](#operators)

---

## Kubernetes Architecture

### Control Plane Components

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES CONTROL PLANE                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                         API SERVER (kube-apiserver)                      │   │
│   │   • Central management point for the cluster                            │   │
│   │   • REST API for all operations                                          │   │
│   │   • Authentication, Authorization, Admission Control                     │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                      │                                           │
│           ┌──────────────────────────┼──────────────────────────┐               │
│           │                          │                          │               │
│           ▼                          ▼                          ▼               │
│   ┌───────────────┐         ┌───────────────┐         ┌───────────────┐        │
│   │    etcd       │         │  Controller   │         │   Scheduler   │        │
│   │               │         │   Manager     │         │               │        │
│   │ • Key-value   │         │               │         │ • Pod         │        │
│   │   store       │         │ • Node        │         │   placement   │        │
│   │ • Cluster     │         │ • Replication │         │ • Resource    │        │
│   │   state       │         │ • Endpoint    │         │   awareness   │        │
│   │ • Consistent  │         │ • Service     │         │ • Affinity    │        │
│   │   & HA        │         │   Account     │         │   rules       │        │
│   └───────────────┘         └───────────────┘         └───────────────┘        │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Node Components

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              WORKER NODE                                         │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                              KUBELET                                     │   │
│   │   • Node agent running on every node                                    │   │
│   │   • Registers node with control plane                                   │   │
│   │   • Ensures containers are running in Pods                              │   │
│   │   • Reports node and pod status                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                           KUBE-PROXY                                     │   │
│   │   • Network proxy on each node                                          │   │
│   │   • Maintains network rules (iptables/IPVS)                             │   │
│   │   • Enables Service abstraction                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                       CONTAINER RUNTIME                                  │   │
│   │   • containerd, CRI-O, or other CRI-compliant runtime                   │   │
│   │   • Pulls images, runs containers                                       │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐             │
│   │      Pod A       │  │      Pod B       │  │      Pod C       │             │
│   │  ┌────┐ ┌────┐  │  │  ┌────┐         │  │  ┌────┐ ┌────┐  │             │
│   │  │ C1 │ │ C2 │  │  │  │ C1 │         │  │  │ C1 │ │ C2 │  │             │
│   │  └────┘ └────┘  │  │  └────┘         │  │  └────┘ └────┘  │             │
│   └──────────────────┘  └──────────────────┘  └──────────────────┘             │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Request Flow

```
User/kubectl
      │
      ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ API Server  │───▶│    etcd     │    │ Controllers │
│             │◀───│   (store)   │    │   watch &   │
│ • Authn     │    └─────────────┘    │   reconcile │
│ • Authz     │◀───────────────────────┤             │
│ • Admission │                        └─────────────┘
└──────┬──────┘
       │
       ▼
┌─────────────┐    ┌─────────────┐
│  Scheduler  │───▶│   Kubelet   │
│  (assigns   │    │ (runs pods) │
│   nodes)    │    └─────────────┘
└─────────────┘
```

---

## Core Concepts

### Pods

The **smallest deployable unit** in Kubernetes. A Pod represents a single instance of a running process.

**Pod Characteristics:**
- One or more containers sharing network/storage
- Unique IP address within the cluster
- Ephemeral - not designed to survive failures
- Managed by higher-level controllers

**Pod Lifecycle:**
```
Pending ──▶ Running ──▶ Succeeded/Failed

Pending:   Pod accepted, waiting for scheduling/images
Running:   At least one container running
Succeeded: All containers exited successfully
Failed:    At least one container failed
```

**Container States:**
- **Waiting** - Not yet running (pulling image, etc.)
- **Running** - Executing
- **Terminated** - Finished execution

### Labels and Selectors

**Labels** are key-value pairs attached to objects for identification.

```yaml
metadata:
  labels:
    app: nginx
    environment: production
    tier: frontend
    version: v1.2.3
```

**Selectors** filter objects based on labels:

```yaml
# Equality-based
selector:
  matchLabels:
    app: nginx

# Set-based
selector:
  matchExpressions:
    - key: environment
      operator: In
      values: [production, staging]
    - key: tier
      operator: NotIn
      values: [backend]
```

### Namespaces

**Namespaces** provide a mechanism for isolating groups of resources.

**Default Namespaces:**
| Namespace | Purpose |
|-----------|---------|
| `default` | Default namespace for objects |
| `kube-system` | Kubernetes system components |
| `kube-public` | Publicly accessible data |
| `kube-node-lease` | Node heartbeats |

**Use Cases:**
- Environment separation (dev, staging, prod)
- Team isolation
- Resource quota management
- RBAC boundaries

---

## Workload Resources

### Deployments

**Deployment** manages ReplicaSets and provides declarative updates for Pods.

```
Deployment
    │
    └── ReplicaSet (current)
    │       └── Pod 1      Manages desired
    │       └── Pod 2  ◀── number of replicas
    │       └── Pod 3
    │
    └── ReplicaSet (previous) ◀── Kept for rollback
```

**Update Strategies:**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| RollingUpdate | Gradually replace pods | Default, zero-downtime |
| Recreate | Kill all, then create new | Database, stateful |

**RollingUpdate Parameters:**
- `maxUnavailable`: Max pods that can be unavailable
- `maxSurge`: Max pods above desired count

### StatefulSets

For **stateful applications** that require:
- Stable, unique network identifiers
- Persistent storage
- Ordered deployment and scaling
- Ordered, graceful deletion

```
StatefulSet: mysql
    │
    ├── mysql-0 ──▶ pvc-mysql-0 ──▶ PV-0
    ├── mysql-1 ──▶ pvc-mysql-1 ──▶ PV-1
    └── mysql-2 ──▶ pvc-mysql-2 ──▶ PV-2
    
    DNS: mysql-0.mysql.namespace.svc.cluster.local
```

### DaemonSets

Ensures a copy of a Pod runs on **all (or some) nodes**.

**Use Cases:**
- Log collectors (Fluentd, Filebeat)
- Monitoring agents (Prometheus node exporter)
- Network plugins (Calico, Cilium)
- Storage daemons (GlusterFS)

### Jobs and CronJobs

**Job:** Creates one or more Pods to run to completion.

```yaml
spec:
  completions: 5      # Total successful completions needed
  parallelism: 2      # Max concurrent pods
  backoffLimit: 3     # Retries before marking failed
  activeDeadlineSeconds: 600  # Timeout
```

**CronJob:** Creates Jobs on a schedule.

```yaml
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  concurrencyPolicy: Forbid  # Replace, Allow, Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

---

## Networking

### Kubernetes Networking Model

**Fundamental Principles:**
1. All Pods can communicate with all other Pods without NAT
2. All Nodes can communicate with all Pods without NAT
3. The IP that a Pod sees itself as is the same IP others see

### Services

**Service Types:**

| Type | Description | Use Case |
|------|-------------|----------|
| ClusterIP | Internal cluster IP | Default, internal services |
| NodePort | Exposes on node IP + port | Development, simple exposure |
| LoadBalancer | Cloud load balancer | Production, external access |
| ExternalName | CNAME redirect | Access external services |

**Service Discovery:**
```
# DNS-based
my-service.my-namespace.svc.cluster.local

# Environment variables
MY_SERVICE_SERVICE_HOST=10.96.0.1
MY_SERVICE_SERVICE_PORT=80
```

### Ingress

**Ingress** manages external access to services, typically HTTP/HTTPS.

```
                        ┌─────────────────────────────────────┐
    Internet            │            Ingress Controller       │
        │               │         (nginx, traefik, etc.)      │
        │               └─────────────────────────────────────┘
        │                              │
        ▼                              │
┌───────────────┐                      │
│    Ingress    │                      │
│    Resource   │                      │
├───────────────┤                      │
│ Rules:        │                      ▼
│ /api/* ──────────────────────▶ api-service:80
│ /web/* ──────────────────────▶ web-service:80
│ /static/* ───────────────────▶ cdn-service:80
└───────────────┘
```

### Network Policies

**Network Policies** control traffic flow between Pods.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: database
      ports:
        - port: 5432
```

---

## Storage

### Storage Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    STORAGE IN KUBERNETES                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Pod                                                        │
│   └── Container                                              │
│       └── volumeMounts                                       │
│           └── Volumes                                        │
│               │                                              │
│               ├── emptyDir (ephemeral)                       │
│               ├── hostPath (node filesystem)                 │
│               ├── configMap / secret                         │
│               └── persistentVolumeClaim ─────┐               │
│                                              │               │
│   PersistentVolumeClaim (PVC)  ◀─────────────┘               │
│   └── Requests storage from PV                               │
│       │                                                      │
│       ▼                                                      │
│   PersistentVolume (PV)                                      │
│   └── Actual storage resource                                │
│       │                                                      │
│       ▼                                                      │
│   StorageClass                                               │
│   └── Dynamic provisioner                                    │
│       │                                                      │
│       ▼                                                      │
│   Cloud Provider / Storage Backend                           │
│   (AWS EBS, GCP PD, NFS, Ceph, etc.)                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Access Modes

| Mode | Abbrev | Description |
|------|--------|-------------|
| ReadWriteOnce | RWO | Read-write by single node |
| ReadOnlyMany | ROX | Read-only by many nodes |
| ReadWriteMany | RWX | Read-write by many nodes |
| ReadWriteOncePod | RWOP | Read-write by single pod |

### Reclaim Policies

| Policy | Description |
|--------|-------------|
| Retain | Keep PV data after PVC deletion |
| Delete | Delete PV and underlying storage |
| Recycle | Basic scrub (deprecated) |

---

## Security

### RBAC (Role-Based Access Control)

```
┌─────────────────────────────────────────────────────────────┐
│                      RBAC Components                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Subject (Who)                                              │
│   ├── User                                                   │
│   ├── Group                                                  │
│   └── ServiceAccount                                         │
│                                                              │
│   Role (What)                                                │
│   ├── Role (namespace-scoped)                               │
│   └── ClusterRole (cluster-scoped)                          │
│                                                              │
│   Binding (Connect Who to What)                             │
│   ├── RoleBinding                                           │
│   └── ClusterRoleBinding                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Pod Security

**Security Context:**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

**Pod Security Standards:**

| Level | Description |
|-------|-------------|
| Privileged | Unrestricted |
| Baseline | Minimally restrictive, prevent known escalations |
| Restricted | Heavily restricted, security best practices |

### Secrets Management

**Secret Types:**
- `Opaque` - Arbitrary user-defined data
- `kubernetes.io/tls` - TLS certificates
- `kubernetes.io/dockerconfigjson` - Docker registry auth
- `kubernetes.io/service-account-token` - SA tokens

**Best Practices:**
1. Use external secret management (Vault, AWS Secrets Manager)
2. Enable encryption at rest for etcd
3. Use RBAC to restrict secret access
4. Rotate secrets regularly
5. Don't log secrets

---

## Advanced Patterns

### Sidecar Pattern

```
┌─────────────────────────────────────────┐
│                  Pod                     │
│  ┌─────────────┐    ┌─────────────────┐ │
│  │   Main      │    │    Sidecar       │ │
│  │ Container   │◀──▶│   Container      │ │
│  │             │    │                  │ │
│  │  (App)      │    │  (Logging/       │ │
│  │             │    │   Proxy/Auth)    │ │
│  └─────────────┘    └─────────────────┘ │
│        │                    │           │
│        └────────┬───────────┘           │
│                 ▼                       │
│          Shared Volume                  │
└─────────────────────────────────────────┘
```

**Use Cases:**
- Log shipping (Fluentd sidecar)
- Service mesh proxy (Envoy/Istio)
- TLS termination
- Configuration sync

### Init Containers

Init containers run **before** app containers start.

```yaml
spec:
  initContainers:
    - name: wait-for-db
      image: busybox
      command: ['sh', '-c', 'until nc -z db 5432; do sleep 2; done']
    - name: migrate
      image: myapp:migrate
      command: ['./migrate.sh']
  containers:
    - name: app
      image: myapp:latest
```

**Use Cases:**
- Wait for dependencies
- Database migrations
- Clone git repos
- Register with service discovery

### Multi-Container Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| Sidecar | Extend main container | Logging, proxying |
| Ambassador | Proxy to external services | Redis proxy |
| Adapter | Standardize output | Log format conversion |

---

## Operators

### What is an Operator?

An **Operator** extends Kubernetes to automate the management of complex applications.

```
┌─────────────────────────────────────────────────────────────┐
│                     OPERATOR PATTERN                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Custom Resource (CR)          Operator                    │
│   ┌────────────────────┐        ┌─────────────────────────┐ │
│   │ apiVersion: db/v1  │        │   Controller            │ │
│   │ kind: PostgreSQL   │   ─▶   │                         │ │
│   │ spec:              │        │   1. Watch CRs          │ │
│   │   replicas: 3      │        │   2. Compare to desired │ │
│   │   version: 15      │        │   3. Take action        │ │
│   │   backup: daily    │        │   4. Update status      │ │
│   └────────────────────┘        └─────────────────────────┘ │
│                                              │               │
│                                              ▼               │
│                                     ┌───────────────────┐   │
│                                     │ Creates/Manages:  │   │
│                                     │ • StatefulSets    │   │
│                                     │ • Services        │   │
│                                     │ • ConfigMaps      │   │
│                                     │ • Secrets         │   │
│                                     │ • CronJobs        │   │
│                                     └───────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Operator Capability Levels

| Level | Capabilities |
|-------|-------------|
| 1 - Basic Install | Automated install and config |
| 2 - Seamless Upgrades | Patch and minor version upgrades |
| 3 - Full Lifecycle | Backup, recovery, failure recovery |
| 4 - Deep Insights | Metrics, alerts, log processing |
| 5 - Auto Pilot | Auto-scaling, tuning, anomaly detection |

### Popular Operators

- **Prometheus Operator** - Monitoring stack
- **Cert-Manager** - Certificate management
- **Strimzi** - Apache Kafka
- **Zalando Postgres Operator** - PostgreSQL
- **Elasticsearch Operator** - Elastic Stack
