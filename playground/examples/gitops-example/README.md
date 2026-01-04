# GitOps with ArgoCD Example

Demonstrates GitOps principles using ArgoCD for Kubernetes deployments.

## GitOps Principles

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GITOPS WORKFLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    Pull      ┌─────────────┐                               │
│  │   GitHub    │◄─────────────│   ArgoCD    │                               │
│  │  (Source    │              │  (Operator) │                               │
│  │   of Truth) │              └──────┬──────┘                               │
│  └─────────────┘                     │                                       │
│        ▲                             │ Sync                                  │
│        │                             ▼                                       │
│   Developer                  ┌───────────────┐                              │
│   commits                    │  Kubernetes   │                              │
│   changes                    │   Cluster     │                              │
│                              └───────────────┘                              │
│                                                                              │
│  ✅ No direct cluster access for developers                                 │
│  ✅ All changes go through Git (auditable)                                  │
│  ✅ Automatic sync keeps cluster in desired state                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 3. Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 4. Login (admin / <password>)
open https://localhost:8080
```

## Deploy Example Application

```bash
# Apply the ArgoCD application
kubectl apply -f apps/guestbook.yaml

# Watch sync status
argocd app get guestbook
```

## Project Structure

```
gitops-example/
├── apps/                    # ArgoCD Application manifests
│   ├── guestbook.yaml
│   └── multi-env.yaml
└── manifests/               # Kubernetes manifests (synced by ArgoCD)
    ├── base/
    │   ├── deployment.yaml
    │   └── service.yaml
    └── overlays/
        ├── dev/
        ├── staging/
        └── production/
```
