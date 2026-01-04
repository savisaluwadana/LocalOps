# Configuration Management Platform

Centralized configuration management with feature flags, environment-specific configs, and dynamic updates.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                       CONFIGURATION MANAGEMENT PLATFORM                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         CONFIG SOURCES                                         │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Git Repo      │  │   Consul KV     │  │       Vault Secrets             ││  │
│  │  │   (GitOps)      │  │   (Dynamic)     │  │       (Sensitive)               ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                         CONFIG MANAGEMENT                                      │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Spring Cloud  │  │   External      │  │       ConfigMaps                ││  │
│  │  │   Config        │  │   Secrets Op.   │  │       (Kubernetes)              ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                         FEATURE FLAGS                                          │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    LaunchDarkly / Unleash / Flagsmith                    │  │  │
│  │  │                                                                          │  │  │
│  │  │  • Feature toggles       • Percentage rollouts                          │  │  │
│  │  │  • A/B testing           • User targeting                               │  │  │
│  │  │  • Kill switches         • Real-time updates                            │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         CONSUMERS                                              │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Microservices │  │   CI/CD         │  │       Infrastructure            ││  │
│  │  │                 │  │   Pipelines     │  │       (Terraform)               ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Centralized Config** - Single source of truth
- **Environment-Specific** - Per-environment configurations
- **Feature Flags** - Progressive rollouts and A/B testing
- **Dynamic Updates** - Hot reload without restart
- **Secret Management** - Vault integration
- **Audit Trail** - All changes tracked

## Quick Start

```bash
# Deploy configuration service
kubectl apply -k kubernetes/config-service/

# Create application config
kubectl apply -f configs/app-config.yaml

# Deploy feature flag service
helm install unleash unleash/unleash
```

## Configuration Hierarchy

```
Base Config (all environments)
    │
    ├── Development
    │   └── developer overrides
    │
    ├── Staging
    │   └── staging-specific settings
    │
    └── Production
        ├── region: us-east
        └── region: eu-west
```

## Feature Flag Types

| Type | Description | Use Case |
|------|-------------|----------|
| Release Toggle | Enable/disable features | Gradual rollout |
| Experiment | A/B testing | Feature testing |
| Ops Toggle | Circuit breaker | Quick disable |
| Permission | User-based | Premium features |

## Feature Flag Example

```yaml
# Unleash feature flag
feature:
  name: new-checkout-flow
  type: release
  enabled: true
  strategies:
    - name: gradualRolloutUserId
      parameters:
        percentage: 25
    - name: userWithId
      parameters:
        userIds: "user1,user2,user3"
```

## Dynamic Config Updates

```yaml
# ConfigMap with reloader
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  annotations:
    reloader.stakater.com/auto: "true"
data:
  APP_LOG_LEVEL: "INFO"
  APP_CACHE_TTL: "300"
  APP_RATE_LIMIT: "100"
```
