# Full Observability Stack

Enterprise-grade observability platform implementing the three pillars of observability: Metrics, Logs, and Traces. Built with Prometheus, Grafana, Loki, Tempo, and comprehensive SLI/SLO management.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         FULL OBSERVABILITY STACK                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DATA COLLECTION                                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │ Prometheus  │  │   Promtail  │  │  OTel       │  │     Node             ││  │
│  │  │  (Metrics)  │  │   (Logs)    │  │  Collector  │  │   Exporter           ││  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └───────────┬───────────┘│  │
│  └─────────┼────────────────┼────────────────┼─────────────────────┼────────────┘  │
│            │                │                │                     │                │
│  ┌─────────┼────────────────┼────────────────┼─────────────────────┼────────────┐  │
│  │         │           DATA STORAGE          │                     │            │  │
│  │  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────────▼─────────┐  │  │
│  │  │  Mimir      │  │    Loki     │  │   Tempo     │  │      Thanos        │  │  │
│  │  │ (Metrics)   │  │   (Logs)    │  │  (Traces)   │  │   (Long-term)      │  │  │
│  │  │  Replicas   │  │  Scalable   │  │ Distributed │  │     Storage        │  │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────────┬─────────┘  │  │
│  │         └────────────────┼────────────────┼───────────────────┘             │  │
│  │                          │                │                                  │  │
│  └──────────────────────────┼────────────────┼──────────────────────────────────┘  │
│                             │                │                                      │
│  ┌──────────────────────────┼────────────────┼──────────────────────────────────┐  │
│  │                    VISUALIZATION & ALERTING                                   │  │
│  │  ┌───────────────────────▼────────────────▼──────────────────────────────┐   │  │
│  │  │                           GRAFANA                                      │   │  │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │   │  │
│  │  │  │  Dashboards  │  │   Alerts     │  │   SLO        │                 │   │  │
│  │  │  │   (Metrics)  │  │   Manager    │  │  Dashboards  │                 │   │  │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘                 │   │  │
│  │  └────────────────────────────────────────────────────────────────────────┘   │  │
│  │                                                                               │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────────────┐  │  │
│  │  │  Alertmanager  │  │   PagerDuty    │  │         Slack                  │  │  │
│  │  │  (Routing)     │  │   (Paging)     │  │     (Notifications)            │  │  │
│  │  └────────────────┘  └────────────────┘  └────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         SLI/SLO MANAGEMENT                                     │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │    Sloth        │  │   Pyrra         │  │       Error Budgets             ││  │
│  │  │  (SLO Specs)    │  │  (SLO UI)       │  │       (Burn Rate)               ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Metrics** - Prometheus + Mimir for scalable metrics storage
- **Logs** - Loki for efficient log aggregation and querying
- **Traces** - Tempo for distributed tracing with exemplars
- **Unified Dashboards** - Grafana with correlation between signals
- **SLI/SLO** - Sloth for SLO-as-code, Pyrra for visualization
- **Alerting** - Alertmanager with PagerDuty/Slack integration
- **Long-term Storage** - Thanos for multi-year metrics retention
- **Auto-instrumentation** - OpenTelemetry Collector & Operator

## Quick Start

```bash
# Deploy the stack
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install using Kustomize
kubectl apply -k kubernetes/base

# Or use Helm umbrella chart
helm install observability ./helm/observability -n monitoring --create-namespace

# Access points:
# - Grafana: http://localhost:3000 (admin/prom-operator)
# - Prometheus: http://localhost:9090
# - Alertmanager: http://localhost:9093
```

## Directory Structure

```
full-observability-stack/
├── kubernetes/
│   ├── base/
│   │   ├── prometheus/         # Prometheus Operator
│   │   ├── grafana/            # Grafana deployment
│   │   ├── loki/               # Loki for logs
│   │   ├── tempo/              # Tempo for traces
│   │   ├── alertmanager/       # Alert routing
│   │   ├── otel-collector/     # OpenTelemetry
│   │   └── slo/                # SLO configurations
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── production/
├── helm/
│   └── observability/          # Umbrella chart
├── slo/
│   └── specs/                  # SLO specifications
├── dashboards/                 # Grafana dashboards
├── alerts/                     # Alert rules
└── runbooks/                   # Incident runbooks
```

## SLO Configuration

Define SLOs using Sloth:

```yaml
version: "prometheus/v1"
service: "api-gateway"
labels:
  owner: platform-team
slos:
  - name: "requests-availability"
    objective: 99.9
    sli:
      events:
        error_query: sum(rate(http_requests_total{status=~"5.."}[{{.window}}]))
        total_query: sum(rate(http_requests_total[{{.window}}]))
    alerting:
      name: APIGatewayHighErrorRate
      annotations:
        runbook: "https://runbooks.example.com/api-gateway-errors"
```

## Default Dashboards

| Dashboard | Description |
|-----------|-------------|
| Kubernetes Overview | Cluster health, resources |
| SLO Overview | Error budgets, burn rates |
| Service Health | RED metrics per service |
| Infrastructure | Node, Pod, Container metrics |
| Trace Analysis | Latency distributions, errors |

## Alert Tiers

| Tier | Response Time | Method | Example |
|------|--------------|--------|---------|
| P1 - Critical | 5 min | PagerDuty Call | Service down |
| P2 - High | 30 min | PagerDuty SMS | SLO breach |
| P3 - Medium | 4 hours | Slack DM | Warning threshold |
| P4 - Low | Next business day | Slack Channel | Info/Advisory |

## Retention Policies

| Signal | Hot Storage | Warm Storage | Cold Storage |
|--------|-------------|--------------|--------------|
| Metrics | 15 days | 90 days | 2 years |
| Logs | 7 days | 30 days | 1 year |
| Traces | 3 days | 14 days | 30 days |
