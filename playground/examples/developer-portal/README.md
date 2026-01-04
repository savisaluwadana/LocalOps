# Developer Portal (Internal Developer Platform)

Backstage-based Internal Developer Platform (IDP) for self-service infrastructure, service catalog, and developer experience.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER PORTAL (BACKSTAGE)                                 │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         BACKSTAGE CORE                                         │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │  Software   │  │  TechDocs   │  │  Templates  │  │    Search             ││  │
│  │  │  Catalog    │  │   (Docs)    │  │ (Scaffolder)│  │   (Discovery)         ││  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         PLUGINS                                                │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │ Kubernetes  │  │   ArgoCD    │  │  Grafana    │  │    GitHub/GitLab      ││  │
│  │  │             │  │             │  │             │  │                       ││  │
│  │  │ PagerDuty   │  │  CircleCI   │  │  Lighthouse │  │    Cost Insights      ││  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         INTEGRATIONS                                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │   Vault     │  │  Terraform  │  │   ArgoCD    │  │     Crossplane        ││  │
│  │  │  (Secrets)  │  │   (IaC)     │  │  (GitOps)   │  │   (Cloud API)         ││  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Service Catalog** - Centralized inventory of all services
- **Software Templates** - Self-service project scaffolding
- **TechDocs** - Documentation as code
- **Kubernetes Plugin** - K8s workload visibility
- **CI/CD Integration** - GitHub Actions, ArgoCD, CircleCI
- **Observability** - Grafana, PagerDuty integration
- **Cost Insights** - Cloud cost visibility
- **API Docs** - OpenAPI/AsyncAPI documentation

## Quick Start

```bash
# Install Backstage
npx @backstage/create-app@latest

# Deploy to Kubernetes
kubectl apply -k kubernetes/base

# Access: http://localhost:7007
```

## Service Catalog

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payment-service
  description: Payment processing service
  annotations:
    github.com/project-slug: org/payment-service
    backstage.io/techdocs-ref: dir:.
    pagerduty.com/service-id: P1234567
    grafana/dashboard-selector: "app=payment-service"
spec:
  type: service
  lifecycle: production
  owner: team-payments
  system: payment-platform
  dependsOn:
    - resource:postgres-payments
    - component:stripe-gateway
  providesApis:
    - payment-api
```

## Software Templates

Templates enable developers to self-provision:
- New microservices
- Databases and caches
- Kubernetes namespaces
- CI/CD pipelines
- Monitoring dashboards

## Plugins

| Plugin | Purpose |
|--------|---------|
| kubernetes | View pods, deployments |
| argocd | GitOps sync status |
| grafana | Embedded dashboards |
| pagerduty | Incident status |
| cost-insights | Cloud costs |
| lighthouse | Performance audits |
