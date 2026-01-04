# Blue-Green Deployment Example

Demonstrates zero-downtime deployments using blue-green strategy.

## How It Works

```
                    ┌─────────────────┐
                    │   Load Balancer │
                    │    (nginx)      │
                    └────────┬────────┘
                             │
         ┌───────────────────┴───────────────────┐
         │                                       │
         ▼                                       ▼
┌─────────────────────┐           ┌─────────────────────┐
│    BLUE (Active)    │           │   GREEN (Standby)   │
│                     │           │                     │
│  ┌───────────────┐  │           │  ┌───────────────┐  │
│  │   App v1.0    │  │           │  │   App v2.0    │  │
│  │   (3 pods)    │  │           │  │   (3 pods)    │  │
│  └───────────────┘  │           │  └───────────────┘  │
│                     │           │                     │
└─────────────────────┘           └─────────────────────┘
         │                                       │
         └───────────────────┬───────────────────┘
                             ▼
                    ┌─────────────────┐
                    │    Database     │
                    │   (shared)      │
                    └─────────────────┘
```

## Quick Start

```bash
# Start with blue environment active
./scripts/deploy.sh blue v1.0

# Deploy new version to green
./scripts/deploy.sh green v2.0

# Test green environment
curl http://localhost:8080/test-green

# Switch traffic to green
./scripts/switch.sh green

# Rollback to blue if needed
./scripts/switch.sh blue
```

## Benefits

- **Zero downtime**: Users never see an error page
- **Instant rollback**: Just switch traffic back
- **Full testing**: Test new version before switching
- **Safe deployments**: No partial deployments
