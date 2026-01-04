# Metrics Dashboard

Custom application metrics with Prometheus and Grafana.

## Features

- **Custom Metrics** - Counters, gauges, histograms
- **Pre-built Dashboards** - Node.js, PostgreSQL, Redis
- **Alerting** - Prometheus AlertManager
- **Visualization** - Grafana dashboards

## Quick Start

```bash
docker compose up -d

# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)
# App metrics: http://localhost:8000/metrics
```

## Metric Types

| Type | Use Case |
|------|----------|
| Counter | Requests, errors |
| Gauge | Active connections, queue size |
| Histogram | Request duration, response size |
| Summary | Percentiles |
