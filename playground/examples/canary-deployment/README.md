# Canary Deployment Example

Gradual rollout of new versions with traffic splitting.

## How It Works

```
                    100% Traffic
                         │
                         ▼
               ┌─────────────────┐
               │  Load Balancer  │
               │    (nginx)      │
               └────────┬────────┘
                        │
         ┌──────────────┴──────────────┐
         │                             │
     90% │                             │ 10%
         ▼                             ▼
┌─────────────────┐         ┌─────────────────┐
│   Stable v1     │         │   Canary v2     │
│   (3 replicas)  │         │   (1 replica)   │
└─────────────────┘         └─────────────────┘
```

## Rollout Stages

1. **Deploy Canary** (10% traffic)
2. **Monitor metrics** (errors, latency)
3. **Increase traffic** (25% → 50% → 75%)
4. **Full rollout** (100%) or **Rollback**

## Quick Start

```bash
docker compose up -d

# Check which version responds
for i in {1..10}; do curl -s localhost:8080 | jq .version; done

# Increase canary traffic
./scripts/canary.sh 25
./scripts/canary.sh 50

# Promote canary to stable
./scripts/promote.sh

# Rollback if issues
./scripts/rollback.sh
```
