# Real-Time Streaming Analytics

Real-time data processing and analytics platform using Apache Kafka, Flink, and ClickHouse.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    REAL-TIME STREAMING ANALYTICS                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DATA SOURCES                                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │ Web Events  │  │  IoT Sensors│  │ Transactions│  │   Log Streams         ││  │
│  │  │ Clickstream │  │  Telemetry  │  │  Payments   │  │    Metrics            ││  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └───────────┬───────────┘│  │
│  └─────────┼────────────────┼────────────────┼─────────────────────┼────────────┘  │
│            └────────────────┼────────────────┼─────────────────────┘                │
│                             ▼                ▼                                       │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                    KAFKA CLUSTER                                               │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │   Broker 1  │  │   Broker 2  │  │   Broker 3  │  │  Schema Registry      ││  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────────────┘│  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                             │                                                        │
│  ┌──────────────────────────▼─────────────────────────────────────────────────────┐ │
│  │                    STREAM PROCESSING                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │ │
│  │  │                     Apache Flink                                         │  │ │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────┐  │  │ │
│  │  │  │ Aggregations│  │  Joins      │  │  Windows    │  │ CEP (Patterns)│  │  │ │
│  │  │  │  Real-time  │  │  Enrichment │  │  Tumbling   │  │   Fraud Det.  │  │  │ │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────┘  │  │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                             │                                                        │
│  ┌──────────────────────────▼─────────────────────────────────────────────────────┐ │
│  │                    ANALYTICS STORAGE                                           │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│ │
│  │  │   ClickHouse    │  │   Druid         │  │         Elasticsearch           ││ │
│  │  │   (OLAP)        │  │   (Time-series) │  │         (Search)                ││ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Event Streaming** - Kafka for high-throughput messaging
- **Stream Processing** - Flink for complex event processing
- **Real-time OLAP** - ClickHouse for sub-second queries
- **Schema Management** - Confluent Schema Registry
- **Exactly-Once** - End-to-end exactly-once semantics
- **CEP** - Complex event processing for fraud detection
- **Dashboards** - Real-time Grafana & Superset dashboards

## Quick Start

```bash
# Deploy Kafka
helm install kafka bitnami/kafka -f values/kafka.yaml

# Deploy Flink
kubectl apply -f flink/flink-cluster.yaml

# Deploy ClickHouse
helm install clickhouse altinity/clickhouse-operator

# Submit Flink job
./bin/flink run -d streaming-analytics.jar
```

## Use Cases

| Use Case | Latency | Throughput |
|----------|---------|------------|
| Real-time dashboards | < 1s | 100K/s |
| Fraud detection | < 100ms | 50K/s |
| Anomaly detection | < 5s | 500K/s |
| Session analytics | < 10s | 200K/s |

## Kafka Topics

```yaml
topics:
  - name: events.raw
    partitions: 12
    replication: 3
    
  - name: events.enriched
    partitions: 12
    replication: 3
    
  - name: aggregates.1m
    partitions: 6
    replication: 3
    retention: 7d
```
