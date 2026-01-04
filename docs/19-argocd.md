# ArgoCD Complete Guide

## Table of Contents

1. [ArgoCD Fundamentals](#argocd-fundamentals)
2. [Architecture](#architecture)
3. [Declarative Setup](#declarative-setup)
4. [Application Patterns](#application-patterns)
5. [Sync Strategies](#sync-strategies)
6. [Security and Multi-Tenancy](#security-and-multi-tenancy)
7. [Enterprise Patterns](#enterprise-patterns)
8. [Troubleshooting](#troubleshooting)

---

## ArgoCD Fundamentals

### What is ArgoCD?

**ArgoCD** is a declarative, GitOps continuous delivery tool for Kubernetes. It implements the GitOps pattern where:

1.  **Git** is the source of truth for the desired state.
2.  **ArgoCD** runs within the cluster.
3.  **Synchronization** ensures the live state matches the desired state.

### Why ArgoCD?

| Feature | Description |
|---------|-------------|
| **Declarative** | Apps defined as Kubernetes manifests |
| **GitOps** | Git as the single source of truth |
| **Audit Trails** | Full history of deployments (via Git) |
| **Drift Detection** | Alerts when cluster deviates from Git |
| **SSO Integration** | OIDC, OAuth2, LDAP, SAML |
| **Multi-Cluster** | Manage deployments across many clusters |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ARGOCD ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐                                                       │
│   │   Git Repo   │  (Manifests, Helm Charts, Kustomize)                 │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          │ Watch / Pull                                                  │
│          ▼                                                               │
│   ┌──────────────────────────────────────────────────────────┐          │
│   │                    ARGOCD CONTROL PLANE                   │          │
│   │                                                          │          │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐   │          │
│   │  │ API      │  │ Repo     │  │ Application          │   │          │
│   │  │ Server   │  │ Server   │  │ Controller           │   │          │
│   │  └────┬─────┘  └───┬──────┘  └──────┬───────────────┘   │          │
│   │       │            │                │                   │          │
│   │       │            ▼                ▼                   │          │
│   │       │      ┌──────────┐    ┌──────────────┐           │          │
│   │       └─────▶│ Redis    │◀───│ Dex (SSO)    │           │          │
│   │              └──────────┘    └──────────────┘           │          │
│   └──────────────────────────────────────────────────────────┘          │
│                                      │                                   │
│                                      │ Sync / Reconcile                  │
│                                      ▼                                   │
│   ┌──────────────────────────────────────────────────────────┐          │
│   │                    TARGET CLUSTERS                        │          │
│   │                                                          │          │
│   │  ┌──────────────┐    ┌──────────────┐    ┌────────────┐  │          │
│   │  │ Production   │    │  Staging     │    │   Dev      │  │          │
│   │  └──────────────┘    └──────────────┘    └────────────┘  │          │
│   └──────────────────────────────────────────────────────────┘          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Components

1.  **API Server**: Exposes the API for Web UI, CLI, and CI/CD systems.
2.  **Repository Server**: Clones Git repos and generates manifests (via Helm/Kustomize).
3.  **Application Controller**: Reconciles state (compares Git vs Cluster).
4.  **Redis**: Caches manifest data.
5.  **Dex**: Handles identity providers (SSO).

---

## Declarative Setup

### Installing ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### The `Application` CRD

The core building block is the `Application` Custom Resource:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  
  # Source of Truth
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  
  # Destination Cluster
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
  
  # Sync Policy
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### The `AppProject` CRD

Projects group applications and enforce restrictions:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  description: My Application Project
  
  # Allow deployment only to specific clusters/namespaces
  destinations:
    - namespace: my-app-*
      server: https://kubernetes.default.svc
  
  # Whitelist source repositories
  sourceRepos:
    - "https://github.com/myorg/*"
  
  # Limit resource kinds
  clusterResourceWhitelist:
    - group: ''
      kind: Deployment
    - group: ''
      kind: Service
```

---

## Application Patterns

### App of Apps Pattern

Manage the ArgoCD configuration itself using GitOps.

```yaml
# root-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/infra
    path: applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
```

Inside `applications/` folder in Git:
- `prometheus.yaml`
- `grafana.yaml`
- `backend.yaml`

ArgoCD watches the `root-app`, which deploys the child apps.

### ApplicationSet

Automate creating Applications based on generators (Git files, folders, clusters).

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-addons
  namespace: argocd
spec:
  generators:
    # Generate apps for all clusters defined in ArgoCD secrets
    - clusters: {}
  template:
    metadata:
      name: '{{name}}-prometheus'
    spec:
      project: default
      source:
        repoURL: https://prometheus-community.github.io/helm-charts
        chart: kube-prometheus-stack
        targetRevision: 45.7.1
      destination:
        server: '{{server}}'
        namespace: monitoring
```

---

## Sync Strategies

### Auto-Sync

```yaml
spec:
  syncPolicy:
    automated:
      prune: true       # Delete resources not in Git
      selfHeal: true    # Revert manual changes in cluster
```

### Sync Options

- `CreateNamespace=true`: Auto-create target namespace.
- `ApplyOutOfSyncOnly=true`: Only sync changed resources (performance).
- `PrunePropagationPolicy=foreground`: Cascade deletion.

### Sync Phases

1.  **PreSync**: Database migrations, backups.
2.  **Sync**: Applying manifests (Deployment, Service).
3.  **PostSync**: Notifications, health checks.

```yaml
# Migration Job
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
```

---

## Security and Multi-Tenancy

### SSO Integration

Configure `argocd-cm` ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
data:
  url: https://argocd.example.com
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: <ID>
          clientSecret: <Secret>
          orgs:
            - name: myorg
```

### RBAC

Configure `argocd-rbac-cm`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
data:
  policy.csv: |
    # Grant 'read-only' role to 'developers' group
    g, developers, role:readonly
    # Grant 'admin' role to 'ops' group
    g, ops, role:admin
```

---

## Enterprise Patterns

### Progressive Delivery (Argo Rollouts)

ArgoCD manages the Rollout resource, but Argo Rollouts controls the traffic shift.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: {duration: 1h}
        - setWeight: 50
        - pause: {duration: 2h}
```

### Managing Secrets

1.  **External Secrets Operator**: Fetch secrets from Vault/AWS.
2.  **Sealed Secrets**: Encrypt secrets in Git.
3.  **ArgoCD Vault Plugin**: Inject secrets during ArgoCD manifest generation.

---

## Troubleshooting

### App Status

- **Healthy**: Resource health checks pass (Pods running).
- **Synced**: Cluster matches Git.
- **OutOfSync**: Cluster differs from Git.
- **Unknown**: Can't verify status.

### Common Issues

1.  **Sync Failed**: Invalid manifest or admission controller rejection.
    *   *Fix*: Check `kubectl describe` or ArgoCD UI logs.
2.  **Resource Stuck (Terminating)**: Finalizers blocking deletion.
    *   *Fix*: Patch remove finalizers (carefully).
3.  **Connection Refused**: ArgoCD can't reach Git or Cluster.
    *   *Fix*: Check network policies, secret credentials.

### CLI Debugging

```bash
argocd app get my-app
argocd app sync my-app
argocd app history my-app
argocd app logs my-app
```
