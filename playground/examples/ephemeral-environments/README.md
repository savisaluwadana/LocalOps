# Ephemeral Environments Platform

On-demand preview environments for every pull request with automatic provisioning and cleanup.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      EPHEMERAL ENVIRONMENTS PLATFORM                                 │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         TRIGGER SOURCES                                        │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │  Pull Request   │  │   Manual        │  │       Scheduled                 ││  │
│  │  │   (GitHub/GL)   │  │   Request       │  │       (QA/Demo)                 ││  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────────┬────────────────────┘│  │
│  └───────────┼───────────────────┬┴────────────────────────┘                     │  │
│              │                   │                                                │  │
│  ┌───────────▼───────────────────▼───────────────────────────────────────────────┐  │
│  │                    ORCHESTRATION LAYER                                         │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   ArgoCD        │  │   Crossplane    │  │       External DNS              ││  │
│  │  │  (Apps)         │  │   (Resources)   │  │       (Routing)                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                    ENVIRONMENT COMPONENTS                                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │  Namespace  │  │  Database   │  │  Services   │  │    Ingress            ││  │
│  │  │  (Isolated) │  │  (Cloned)   │  │  (Deployed) │  │   pr-123.preview.com  ││  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **PR-based Environments** - Automatic environment per pull request
- **Namespace Isolation** - Each environment in its own namespace
- **Database Seeding** - Clone production data (anonymized)
- **Dynamic DNS** - Unique URLs for each environment
- **Auto-cleanup** - TTL-based or on PR close
- **GitHub Integration** - Comment with environment URL
- **Resource Quotas** - Limit resources per environment

## Quick Start

```bash
# Install controller
kubectl apply -k kubernetes/controller/

# Configure GitHub webhook
./scripts/configure-webhook.sh

# Create manual environment
kubectl apply -f examples/manual-env.yaml
```

## Environment Lifecycle

```
PR Opened → Environment Created → App Deployed → Tests Run → PR Merged → Cleanup
    │              │                    │            │           │           │
    │              │                    │            │           │           └── Auto-delete
    │              │                    │            │           └── Merge to main
    │              │                    │            └── E2E tests pass
    │              │                    └── Build & deploy preview
    │              └── Namespace, DB, Ingress created
    └── Webhook triggers controller
```

## Configuration

```yaml
apiVersion: preview.io/v1alpha1
kind: PreviewEnvironment
metadata:
  name: pr-123
spec:
  pullRequest:
    number: 123
    repository: org/app
    branch: feature/new-login
    sha: abc123
  
  ttl: 72h  # Auto-cleanup after 72 hours
  
  application:
    image: gcr.io/project/app:pr-123
    replicas: 1
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
  
  database:
    type: postgresql
    seed: production-anonymized
    size: 1Gi
  
  ingress:
    host: pr-123.preview.example.com
    tls: true
```

## Resource Quotas

| Tier | Max Envs | CPU | Memory | Storage |
|------|----------|-----|--------|---------|
| Lite | 5 | 500m | 512Mi | 1Gi |
| Standard | 10 | 1 | 1Gi | 5Gi |
| Enterprise | Unlimited | 2 | 2Gi | 10Gi |

## Cost Optimization

- **Idle Detection** - Scale down inactive environments
- **Scheduled Shutdown** - Turn off during non-business hours
- **Spot Instances** - Use preemptible nodes
- **Shared Resources** - Common databases for read-only data
