# Monitoring & Observability

## Overview

Monitoring is essential in DevOps. This guide covers the **Prometheus + Grafana** stack - the industry standard for metrics collection and visualization.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONITORING STACK                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Applications    ┌───────────┐    ┌───────────┐    ┌──────────┐ │
│  & Services ───► │Prometheus │───►│  Grafana  │───►│   You    │ │
│  (metrics)       │ (collect) │    │(visualize)│    │(dashboards)│
│                  └───────────┘    └───────────┘    └──────────┘ │
│                        │                                         │
│                        ▼                                         │
│                  ┌───────────┐                                   │
│                  │Alertmanager│──► Slack/Email/PagerDuty        │
│                  └───────────┘                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### Prometheus

**Prometheus** is a time-series database that:
- **Scrapes** metrics from targets at regular intervals
- **Stores** data efficiently with compression
- Uses **PromQL** for querying

**Metric Types:**
| Type | Description | Example |
|------|-------------|---------|
| Counter | Only increases | `http_requests_total` |
| Gauge | Can go up/down | `memory_usage_bytes` |
| Histogram | Distributions | `request_duration_seconds` |
| Summary | Similar to histogram | `request_latency` |

### Grafana

**Grafana** is a visualization platform that:
- Creates beautiful dashboards
- Supports multiple data sources
- Provides alerting capabilities

---

## Hands-On: Deploy Monitoring Stack

### Docker Compose Setup

Create `playground/monitoring/docker-compose.yml`:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

Create `playground/monitoring/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
```

### Start the Stack

```bash
cd playground/monitoring
docker compose up -d

# Access:
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin123)
# Node Exporter: http://localhost:9100/metrics
```

### Configure Grafana

1. Login to Grafana (admin/admin123)
2. Go to **Configuration → Data Sources**
3. Add **Prometheus** with URL: `http://prometheus:9090`
4. Import dashboard ID **1860** (Node Exporter Full)

---

## PromQL Examples

```promql
# CPU Usage %
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage %
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk Usage %
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100

# HTTP Request Rate
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

---

## Kubernetes Monitoring

For K8s, use **kube-prometheus-stack** (Helm chart):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

Access Grafana:
```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
# Default: admin/prom-operator
```
