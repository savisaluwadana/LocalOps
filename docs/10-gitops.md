# GitOps Complete Guide

## Table of Contents

1. [GitOps Fundamentals](#gitops-fundamentals)
2. [Core Principles](#core-principles)
3. [GitOps vs Traditional CI/CD](#gitops-vs-traditional-cicd)
4. [ArgoCD](#argocd)
5. [Flux](#flux)
6. [Repository Strategies](#repository-strategies)
7. [Best Practices](#best-practices)

---

## GitOps Fundamentals

### What is GitOps?

**GitOps** is an operational model for cloud-native applications. It uses Git as the single source of truth for declarative infrastructure and applications.

### The Core Idea

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         GITOPS MODEL                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Traditional:                                                           │
│   Developer → CI Pipeline → kubectl apply → Cluster                     │
│               (push-based)                                               │
│                                                                          │
│   GitOps:                                                                │
│   Developer → Git Repo ← GitOps Operator → Cluster                      │
│              (commit)   (pull-based)                                     │
│                                                                          │
│   Key difference: The CLUSTER pulls from Git,                           │
│                   not the CI pushes to cluster                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Core Principles

### 1. Declarative Configuration

Everything is defined as code - infrastructure, applications, policies.

```yaml
# What you want, not how to do it
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
```

### 2. Git as Single Source of Truth

- All desired state is in Git
- Git history = audit log
- Git branches = environments

### 3. Automated Synchronization

GitOps operators continuously reconcile:

```
Git State (Desired) ←→ Cluster State (Actual)
        │                       │
        └───────────────────────┘
             Sync/Reconcile
```

### 4. Continuous Reconciliation

The operator doesn't just sync once - it continuously ensures the cluster matches Git.

---

## GitOps vs Traditional CI/CD

| Aspect | Traditional CI/CD | GitOps |
|--------|-------------------|--------|
| Deployment trigger | CI pipeline (push) | Git commit (pull) |
| Who accesses cluster | CI system | GitOps operator only |
| Rollback | Re-run pipeline | Git revert |
| Drift detection | Manual/none | Automatic |
| Audit trail | CI logs | Git history |
| Credentials | CI needs kubectl | Operator runs in cluster |

---

## ArgoCD

### What is ArgoCD?

**ArgoCD** is a declarative GitOps continuous delivery tool for Kubernetes.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ARGOCD ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐                                                       │
│   │   Git Repo   │  ← Source of truth                                   │
│   │  (manifests) │                                                       │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          │ pull                                                          │
│          ▼                                                               │
│   ┌──────────────────────────────────────────────────────────┐          │
│   │                    ARGOCD                                 │          │
│   │                                                          │          │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐   │          │
│   │  │ Repo     │  │ App      │  │ Application          │   │          │
│   │  │ Server   │→ │ Controller│→ │ Controller          │   │          │
│   │  └──────────┘  └──────────┘  └──────────────────────┘   │          │
│   │                                        │                 │          │
│   │  ┌──────────┐              apply      │                 │          │
│   │  │ API      │              ▼          │                 │          │
│   │  │ Server   │        ┌─────────────┐  │                 │          │
│   │  └──────────┘        │ Kubernetes  │  │                 │          │
│   │       ▲              │ Cluster     │◀─┘                 │          │
│   │       │              └─────────────┘                    │          │
│   │  ┌────────────┐                                         │          │
│   │  │  Web UI    │                                         │          │
│   │  └────────────┘                                         │          │
│   └──────────────────────────────────────────────────────────┘          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Application Definition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/myorg/my-app-config
    targetRevision: main
    path: k8s/production
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true       # Delete resources not in Git
      selfHeal: true    # Fix drift automatically
    syncOptions:
      - CreateNamespace=true
```

### Sync Strategies

| Strategy | Description | Use Case |
|----------|-------------|----------|
| Manual | Click to sync | Production |
| Automated | Sync on Git changes | Dev/staging |
| Self-heal | Fix drift automatically | All environments |
| Prune | Delete orphaned resources | All environments |

---

## Flux

### What is Flux?

**Flux** is a GitOps toolkit for Kubernetes, part of the CNCF.

### Core Components

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          FLUX COMPONENTS                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   source-controller    ─▶ Fetches from Git, Helm, OCI                   │
│                                                                          │
│   kustomize-controller ─▶ Applies Kustomize overlays                    │
│                                                                          │
│   helm-controller      ─▶ Manages Helm releases                         │
│                                                                          │
│   notification-controller ─▶ Handles alerts and webhooks                │
│                                                                          │
│   image-automation      ─▶ Updates Git when new images available        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### GitRepository Definition

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/myorg/my-app-config
  ref:
    branch: main
  secretRef:
    name: git-credentials
```

### Kustomization Definition

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: my-app
  path: ./k8s/production
  prune: true
  healthChecks:
    - kind: Deployment
      name: my-app
      namespace: production
```

---

## Repository Strategies

### Mono-repo

All environments in one repository:

```
my-app-config/
├── base/
│   ├── deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── development/
│   │   └── kustomization.yaml
│   ├── staging/
│   │   └── kustomization.yaml
│   └── production/
│       └── kustomization.yaml
```

### Multi-repo

Separate repos for app and config:

```
my-app/              # Application code
├── src/
├── Dockerfile
└── .github/workflows/

my-app-config/       # Kubernetes manifests
├── base/
└── overlays/
```

### Comparison

| Aspect | Mono-repo | Multi-repo |
|--------|-----------|------------|
| Simplicity | Single repo | Multiple repos |
| Access control | Harder to separate | Easy to separate |
| Atomicity | All or nothing | Independent changes |
| Best for | Small teams | Large organizations |

---

## Best Practices

### Repository Structure

1. **Separate app code from config** - Different change velocity
2. **Use Kustomize or Helm** - Avoid duplicating manifests
3. **Keep secrets out of Git** - Use Sealed Secrets or external managers

### Security

1. **Limit cluster access** - Only GitOps operator needs it
2. **Sign commits** - Verify who made changes
3. **Protect main branch** - Require reviews

### Operations

1. **Start with non-production** - Test the workflow first
2. **Use progressive delivery** - Canary/blue-green via GitOps
3. **Monitor sync status** - Alert on sync failures

### Example Workflow

```
1. Developer creates PR with manifest changes
2. CI runs validation (kubeval, kustomize build)
3. Reviewer approves and merges
4. GitOps operator detects change
5. Manifests applied to cluster
6. Operator reports sync status
7. Alerts if sync fails
```

This guide covers GitOps fundamentals with practical examples using ArgoCD and Flux for Kubernetes-native continuous delivery.
