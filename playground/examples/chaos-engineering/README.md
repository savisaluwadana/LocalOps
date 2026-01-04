# Chaos Engineering

Testing system resilience by introducing controlled failures.

## Philosophy

> "The best way to avoid failure is to fail constantly." - Netflix

Chaos engineering proactively injects failures to:
- Discover hidden dependencies
- Test recovery mechanisms
- Build confidence in systems

## Experiments

| Experiment | Tests |
|------------|-------|
| **Container Kill** | Restart behavior |
| **Network Latency** | Timeout handling |
| **CPU Stress** | Performance under load |
| **Disk Fill** | Storage handling |
| **DNS Failure** | Service discovery |

## Quick Start

```bash
# Start the stack
docker compose up -d

# Run chaos experiments
./scripts/chaos.sh kill-random
./scripts/chaos.sh network-delay 500ms
./scripts/chaos.sh cpu-stress 80

# Monitor recovery
watch docker compose ps
```

## Safety Rules

1. **Start small** - Test in dev first
2. **Monitor everything** - Watch metrics during experiments
3. **Have rollback ready** - Know how to stop chaos
4. **Communicate** - Tell the team before chaos
5. **Blame-free** - Learn from failures
