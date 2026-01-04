# GitOps with ArgoCD

## What is GitOps?

**GitOps** is a paradigm where Git is the single source of truth for infrastructure and applications. Changes are made via Git commits, and automation syncs the desired state to the cluster.

### GitOps Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                       GITOPS FLOW                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Developer    ┌──────────┐    ┌──────────┐    ┌──────────────┐  │
│  ──────────►  │   Git    │───►│  ArgoCD  │───►│  Kubernetes  │  │
│  (commit)     │  (repo)  │    │  (sync)  │    │  (cluster)   │  │
│               └──────────┘    └──────────┘    └──────────────┘  │
│                    ▲               │                             │
│                    │               │  Continuous                 │
│                    └───────────────┘  Reconciliation             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Benefits

| Traditional | GitOps |
|-------------|--------|
| `kubectl apply` manually | Git push triggers deploy |
| No audit trail | Full Git history |
| Imperative | Declarative |
| Hard to rollback | `git revert` to rollback |

---

## ArgoCD Setup

### Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

### Access the UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Login: https://localhost:8080
# Username: admin
# Password: (from above)
```

### Install ArgoCD CLI

```bash
brew install argocd

# Login
argocd login localhost:8080 --insecure
```

---

## Hands-On: Deploy an App with GitOps

### 1. Create Application Manifest

Create `playground/argocd/guestbook-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 2. Apply and Watch

```bash
kubectl apply -f playground/argocd/guestbook-app.yaml

# Watch sync status
argocd app get guestbook

# View in UI at https://localhost:8080
```

### 3. Create Your Own GitOps Repo

Structure:
```
my-gitops-repo/
├── apps/
│   ├── dev/
│   │   └── nginx.yaml
│   ├── staging/
│   │   └── nginx.yaml
│   └── prod/
│       └── nginx.yaml
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── README.md
```

---

## Best Practices

1. **Separate config from code** - App code and K8s manifests in different repos
2. **Use Kustomize or Helm** - For environment-specific configs
3. **Enable auto-sync with selfHeal** - Prevents drift
4. **Use ApplicationSets** - Manage multiple environments
5. **Implement RBAC** - Control who can sync what
