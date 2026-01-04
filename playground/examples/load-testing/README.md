# Load Testing with k6

Performance testing your applications using k6.

## Quick Start

```bash
# Install k6
brew install k6

# Run basic load test
k6 run scripts/basic.js

# Run with Docker
docker compose up -d
```

## Test Types

| Type | Purpose | Script |
|------|---------|--------|
| Smoke | Verify system works | `scripts/smoke.js` |
| Load | Normal traffic simulation | `scripts/load.js` |
| Stress | Find breaking point | `scripts/stress.js` |
| Spike | Sudden traffic bursts | `scripts/spike.js` |
| Soak | Extended duration | `scripts/soak.js` |

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│       k6        │────►│    Target App   │────►│    Database     │
│  (load driver)  │     │    (nginx)      │     │    (postgres)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│   InfluxDB      │
│   + Grafana     │
│   (metrics)     │
└─────────────────┘
```

## Running Tests

```bash
# Basic test
k6 run scripts/load.js

# With options
k6 run --vus 50 --duration 60s scripts/load.js

# Export to InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 scripts/load.js
```
