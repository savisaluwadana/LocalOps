# Observability and Monitoring Complete Guide

## Table of Contents

1. [Observability Fundamentals](#observability-fundamentals)
2. [The Three Pillars](#the-three-pillars)
3. [Metrics with Prometheus](#metrics-with-prometheus)
4. [Visualization with Grafana](#visualization-with-grafana)
5. [Logging Architecture](#logging-architecture)
6. [Distributed Tracing](#distributed-tracing)
7. [Alerting Strategies](#alerting-strategies)
8. [SLIs, SLOs, and SLAs](#slis-slos-and-slas)
9. [Best Practices](#best-practices)

---

## Observability Fundamentals

### What is Observability?

**Observability** is the ability to understand the internal state of a system by examining its external outputs.

### Monitoring vs Observability

| Aspect | Monitoring | Observability |
|--------|------------|---------------|
| Focus | Known unknowns | Unknown unknowns |
| Approach | Predefined metrics | Exploratory queries |
| Questions | "Is CPU high?" | "Why are German users slow?" |
| Style | Dashboard-centric | Query-centric |

---

## The Three Pillars

### Overview

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   METRICS    │   │    LOGS      │   │   TRACES     │
├──────────────┤   ├──────────────┤   ├──────────────┤
│ Quantitative │   │ Qualitative  │   │ Causal       │
│ measurements │   │ events with  │   │ relationships│
│ over time    │   │ context      │   │ between svcs │
│              │   │              │   │              │
│ WHAT is      │   │ WHY it       │   │ WHERE it     │
│ happening?   │   │ happened?    │   │ happened?    │
└──────────────┘   └──────────────┘   └──────────────┘
```

### Metrics

**Numbers that describe system behavior over time.**

| Type | Description | Example |
|------|-------------|---------|
| **Counter** | Only goes up | Total requests |
| **Gauge** | Goes up or down | Temperature |
| **Histogram** | Distribution | Request latency buckets |

### Logs

**Timestamped records of discrete events.**

```
2024-01-15 INFO  [user-service] Login successful user_id=12345
2024-01-15 ERROR [order-service] Payment failed order_id=67890
```

### Traces

**The path of a request through distributed services.**

```
Trace ID: abc123
├── [API Gateway]     250ms total
│   ├── [Auth Svc]    45ms
│   └── [Order Svc]   150ms
│       └── [DB]      50ms
```

---

## Metrics with Prometheus

### Architecture

Prometheus uses a **pull model** - it scrapes metrics from target endpoints.

```
┌──────────────┐     ┌──────────────┐
│ Application  │     │ Application  │
│  /metrics    │     │  /metrics    │
└──────┬───────┘     └──────┬───────┘
       │   PULL             │
       ▼                    ▼
┌─────────────────────────────────┐
│      PROMETHEUS SERVER          │
│  ┌─────────┐  ┌──────────────┐  │
│  │ Scraper │─▶│ Time Series  │  │
│  └─────────┘  │   Database   │  │
│               └──────────────┘  │
└───────────────┬─────────────────┘
                │
        ┌───────┴───────┐
        ▼               ▼
  ┌──────────┐   ┌─────────────┐
  │ Grafana  │   │ Alertmanager│
  └──────────┘   └─────────────┘
```

### PromQL Examples

```promql
# Request rate per second
rate(http_requests_total[5m])

# Error rate percentage
sum(rate(http_requests_total{status=~"5.."}[5m])) / 
sum(rate(http_requests_total[5m])) * 100

# P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

---

## Visualization with Grafana

### Design Methods

**RED Method (Services):**
- **R**ate: Request throughput
- **E**rrors: Failed requests
- **D**uration: Latency

**USE Method (Resources):**
- **U**tilization: % busy
- **S**aturation: Queue length
- **E**rrors: Error count

---

## Logging Architecture

### Centralized Logging

```
Apps → Log Shipper → Storage → Visualization
       (Fluentd)    (Loki)    (Grafana)
```

### Structured Logging

```json
{
  "timestamp": "2024-01-15T10:23:45Z",
  "level": "INFO",
  "service": "auth-service",
  "message": "User logged in",
  "user_id": "12345",
  "trace_id": "abc123"
}
```

---

## Distributed Tracing

### How It Works

1. Generate **trace_id** at entry point
2. Each service creates a **span**
3. Spans linked via **parent_id**
4. All spans share same **trace_id**

### Tools

| Tool | Description |
|------|-------------|
| **Jaeger** | Open source tracing |
| **Zipkin** | Twitter's tracing |
| **Tempo** | Grafana's trace storage |
| **OpenTelemetry** | Vendor-neutral standard |

---

## Alerting Strategies

### Good Alert Design

| Principle | Bad Example | Good Example |
|-----------|-------------|--------------|
| Symptom-based | CPU > 80% | Error rate > 1% |
| Has duration | Instant trigger | For 5 minutes |
| Actionable | "Something's wrong" | Link to runbook |

### Severity Levels

| Level | Response | Example |
|-------|----------|---------|
| Critical | Immediate | Site down |
| Warning | Hours | Degraded perf |
| Info | Next sprint | Cleanup needed |

---

## SLIs, SLOs, and SLAs

### Definitions

- **SLI**: Measurement (P99 = 145ms)
- **SLO**: Target (P99 < 200ms)
- **SLA**: Contract with consequences

### Error Budget

If SLO = 99.9% availability per month:
- 30 days = 43,200 minutes
- 0.1% = 43.2 minutes allowed downtime

This is your **error budget** to "spend" on deployments and incidents.

---

## Best Practices

### Instrumentation

1. Instrument at service boundaries
2. Include request identifiers
3. Log structured data (JSON)
4. Use consistent naming

### Dashboards

1. Start with golden signals
2. Show what's "normal"
3. Link to runbooks

### Alerting

1. Alert on symptoms, not causes
2. Require duration (avoid flapping)
3. Include runbook links
4. Test alerts regularly
