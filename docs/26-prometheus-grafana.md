# Prometheus and Grafana Deep Dive

## Table of Contents

1. [Prometheus Architecture](#prometheus-architecture)
2. [PromQL Theory](#promql-theory)
3. [AlertManager](#alertmanager)
4. [Grafana Deep Dive](#grafana-deep-dive)
5. [Production Patterns](#production-patterns)

---

## Prometheus Architecture

### Component Breakdown

**Prometheus** is a time-series database and monitoring system designed for reliability and simplicity.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     PROMETHEUS SERVER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐            │
│   │ Retrieval    │     │    TSDB      │     │  HTTP API    │            │
│   │ (Scraper)    │────▶│ (Storage)    │◀────│ (PromQL)     │            │
│   └──────▲───────┘     └──────┬───────┘     └──────▲───────┘            │
│          │                    │                    │                    │
│          │ Pull               │ Rules              │ Query              │
│          │                    ▼                    │                    │
│   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐            │
│   │  Targets     │     │  Recording   │     │   Grafana    │            │
│   │ (Exporters)  │     │   Rules      │     │  (Visual)    │            │
│   └──────────────┘     └──────────────┘     └──────────────┘            │
│                               |                                          │
│                               ▼                                          │
│                        ┌──────────────┐                                  │
│                        │ AlertManager │                                  │
│                        └──────────────┘                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### The Data Model

Prometheus stores all data as **time series**: streams of timestamped values belonging to the same metric and the same set of labeled dimensions.

**Format:**
```
<metric name>{<label name>=<label value>, ...}
```

**Example:**
```
api_http_requests_total{method="POST", handler="/messages"}
```

### Storage (TSDB)
- **Head Block**: In-memory, strictly ordered.
- **Persistent Blocks**: Immutable, stored on disk (2h default duration).
- **Compaction**: Merges smaller blocks into larger ones to save space.
- **WAL (Write Ahead Log)**: Ensures durability in case of crashes.

---

## PromQL Theory

**PromQL** (Prometheus Query Language) is a functional language for evaluating real-time vectors.

### Data Types

1.  **Instant Vector**: A set of time series containing a single sample for each time series, all sharing the same timestamp.
    -   `http_requests_total`
2.  **Range Vector**: A set of time series containing a range of data points over time for each time series.
    -   `http_requests_total[5m]`
3.  **Scalar**: A simple numeric floating point value.
    -   `10.5`

### Operators

-   **Arithmetic**: `+`, `-`, `*`, `/`, `%`, `^`
-   **Comparison**: `==`, `!=`, `>`, `<`, `>=`, `<=`
-   **Logical**: `and`, `or`, `unless`
-   **Aggregation**: `sum`, `min`, `max`, `avg`, `stddev`, `count`, `bottomk`, `topk`

### Rate Functions (Critical)

1.  `rate(v range-vector)`: Calculates per-second average rate of increase. **Handles counter resets** (e.g., app restart).
    -   Use for: Slower moving counters, alerting.
2.  `irate(v range-vector)`: Calculates instant rate based on last two data points.
    -   Use for: High-resolution graphs of volatile metrics.
3.  `increase(v range-vector)`: Calculates the increase in the time range.
    -   `increase(x[5m])` is roughly `rate(x[5m]) * 300`.

### Vector Matching

-   **One-to-One**:
    `method_code:http_errors:rate5m{method="get"} / method:http_requests:rate5m{method="get"}`
-   **Many-to-One** (ignoring labels):
    `http_errors / ignoring(code) group_left http_requests`

---

## AlertManager

AlertManager handles alerts sent by client applications such as the Prometheus server.

### Architecture

```
Prometheus ──▶ AlertManager ──▶ Receiver (Slack/Email/PagerDuty)
```

### Key Logic

1.  **Grouping**: Grouping alerts of similar nature into a single notification.
    -   *Example*: 100 services down? Send 1 "Cluster Down" alert, not 100 emails.
2.  **Inhibition**: Suppress notifications for certain alerts if certain other alerts are firing.
    -   *Example*: If "Region Down" is firing, inhibit "Instance Down".
3.  **Silencing**: Pause alerts for a given time (e.g., during maintenance window).

### Configuration

```yaml
route:
  group_by: ['alertname', 'cluster']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  receiver: 'team-X-pager'
```

---

## Grafana Deep Dive

**Grafana** is the open-source platform for monitoring and observability.

### Data Sources
Grafana supports many backends: Prometheus, Loki, CloudWatch, Elasticsearch, InfluxDB, PostgreSQL, etc.

### Dashboarding Concepts

-   **Rows**: Logical grouping of panels.
-   **Panels**: The basic visualization block (Time series, Gauge, Table, Bar Gague, Stat).
-   **Variables**: Dropdown filters for dynamic dashboards.
    -   `label_values(up, job)` -> creates a dropdown of all jobs.
    -   Use in queries: `rate(http_requests_total{job="$job"}[5m])`.

### Annotations
Overlay events on graphs (e.g., "Deployment Started", "Configuration Changed").
-   Can query Prometheus logic (`process_start_time_seconds`).

### Transformations
Modify data needed for visualization **within** Grafana:
-   Rename fields
-   Calculate difference
-   Join by field (merge data from two queries)

---

## Production Patterns

### Prometheus HA

Prometheus servers are independent. To achieve HA, run **two identical Prometheus servers** scraping the same targets. AlertManager handles deduplication.

```
       ┌──────────────┐
       │ Prometheus A │─────┐
       └──────────────┘     │
Target                      ▼
       ┌──────────────┐   ┌─────────┐
       │ Prometheus B │──▶│ AlertMgr│ (Deduplicates)
       └──────────────┘   └─────────┘
```

### Federation

Allows a Prometheus server to scrape selected time series from another Prometheus server.

-   **Hierarchical Federation**: Leaf Prometheus -> Global Prometheus.
-   **Cross-Service Federation**: Scrape specific data from another team's Prometheus.

### Long Term Storage (Remote Write)

Prometheus is not designed for unlimited long-term storage. Use **Remote Write** API to send data to:
-   **Thanos**: Unlimited storage on S3.
-   **Cortex / Mimir**: Multi-tenant, scalable Prometheus.
-   **VictoriaMetrics**: High performance, compression.

### The "USE" Method Dashboard

For every resource (CPU, Memory, Disk, Network) in Grafana:
1.  **Utilization**: `rate(node_cpu_seconds_total{mode!="idle"}[5m])`
2.  **Saturation**: `node_load1`
3.  **Errors**: `node_network_receive_errs_total`
