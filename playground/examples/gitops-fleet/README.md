# GitOps Fleet Management

Enterprise GitOps platform for managing multiple Kubernetes clusters using ArgoCD and Flux.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        GITOPS FLEET MANAGEMENT                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                    MANAGEMENT CLUSTER                                          │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │  ArgoCD     │  │   Vault     │  │  Crossplane │  │    External Secrets  ││  │
│  │  │ (App of Apps)│ │  (Secrets)  │  │  (Infra)    │  │       Operator       ││  │
│  │  └──────┬──────┘  └─────────────┘  └─────────────┘  └───────────────────────┘│  │
│  └─────────┼─────────────────────────────────────────────────────────────────────┘  │
│            │                                                                         │
│  ┌─────────▼─────────────────────────────────────────────────────────────────────┐  │
│  │                         WORKLOAD CLUSTERS                                      │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Production    │  │    Staging      │  │       Development              ││  │
│  │  │   (3 clusters)  │  │   (2 clusters)  │  │       (5 clusters)             ││  │
│  │  │   us/eu/apac    │  │   us/eu         │  │       per-team                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **App of Apps** - Hierarchical application management
- **Multi-Cluster** - Single pane of glass for all clusters
- **ApplicationSets** - Dynamic app generation
- **Progressive Delivery** - Argo Rollouts integration
- **Secret Management** - External Secrets with Vault
- **Drift Detection** - Automatic sync and alerting
- **RBAC** - Fine-grained access control

## Quick Start

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy bootstrap app
kubectl apply -f bootstrap/root-app.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Directory Structure

```
gitops-fleet/
├── bootstrap/
│   └── root-app.yaml          # Root application
├── clusters/
│   ├── production/            # Production clusters
│   │   ├── us-east/
│   │   ├── eu-west/
│   │   └── apac/
│   ├── staging/
│   └── development/
├── apps/
│   ├── base/                  # Base app definitions
│   └── overlays/              # Cluster-specific overlays
├── infrastructure/
│   ├── cert-manager/
│   ├── external-dns/
│   ├── ingress-nginx/
│   └── monitoring/
└── applicationsets/           # Dynamic app generation
```

## Promotion Flow

```
Dev → Staging → Production
  │       │           │
  │       │           └── Manual approval + auto-sync
  │       └── Auto-sync on staging branch merge
  └── Auto-sync on feature branch merge
```

## Cluster Registration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-addons
spec:
  generators:
    - clusters:
        selector:
          matchLabels:
            env: production
  template:
    metadata:
      name: '{{name}}-addons'
    spec:
      destination:
        server: '{{server}}'
        namespace: kube-system
      source:
        repoURL: https://github.com/org/gitops-fleet
        path: infrastructure
```
