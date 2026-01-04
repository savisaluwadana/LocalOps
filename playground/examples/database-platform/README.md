# Database Platform

Managed database platform with automated provisioning, backup, replication, and monitoring.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DATABASE PLATFORM                                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DATABASE OPERATORS                                     │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   PostgreSQL    │  │   MySQL         │  │       MongoDB                   ││  │
│  │  │   Operator      │  │   Operator      │  │       Operator                  ││  │
│  │  │   (Zalando)     │  │   (Oracle)      │  │       (Percona)                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  │                                                                                │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Redis         │  │   Elasticsearch │  │       Kafka                     ││  │
│  │  │   Operator      │  │   Operator      │  │       Operator                  ││  │
│  │  │   (Spotahome)   │  │   (ECK)         │  │       (Strimzi)                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DATA SERVICES                                          │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Backup/       │  │   Monitoring    │  │       Connection                ││  │
│  │  │   Restore       │  │   (PMM)         │  │       Pooling (PgBouncer)       ││  │
│  │  │   (Velero)      │  │                 │  │                                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DATABASE INSTANCES                                     │  │
│  │                                                                                │  │
│  │   ┌─────────────────────────────────────────────────────────────────────────┐ │  │
│  │   │  PostgreSQL Cluster: orders-db                                          │ │  │
│  │   │  ┌─────────┐  ┌─────────┐  ┌─────────┐                                  │ │  │
│  │   │  │ Primary │─▶│ Replica │─▶│ Replica │   Streaming Replication          │ │  │
│  │   │  └─────────┘  └─────────┘  └─────────┘                                  │ │  │
│  │   └─────────────────────────────────────────────────────────────────────────┘ │  │
│  │                                                                                │  │
│  │   ┌─────────────────────────────────────────────────────────────────────────┐ │  │
│  │   │  Redis Cluster: cache-cluster                                           │ │  │
│  │   │  ┌─────────┐  ┌─────────┐  ┌─────────┐                                  │ │  │
│  │   │  │ Master  │  │ Master  │  │ Master  │   Redis Cluster Mode             │ │  │
│  │   │  │ + Slave │  │ + Slave │  │ + Slave │                                  │ │  │
│  │   │  └─────────┘  └─────────┘  └─────────┘                                  │ │  │
│  │   └─────────────────────────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Self-Service** - Teams provision databases via GitOps
- **High Availability** - Automated failover and replication
- **Backup/Restore** - Scheduled backups with point-in-time recovery
- **Monitoring** - Percona PMM for database insights
- **Connection Pooling** - PgBouncer for PostgreSQL
- **Secret Rotation** - Vault integration for credentials

## Quick Start

```bash
# Install operators
helm install postgres-operator postgres-operator-charts/postgres-operator

# Create a PostgreSQL cluster
kubectl apply -f databases/orders-db.yaml

# Check status
kubectl get postgresql
```

## Database Declaration

```yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: orders-db
spec:
  teamId: "orders-team"
  volume:
    size: 100Gi
    storageClass: fast-ssd
  numberOfInstances: 3
  users:
    app_user:
      - superuser
      - createdb
  databases:
    orders: app_user
  postgresql:
    version: "15"
    parameters:
      max_connections: "200"
      shared_buffers: 1GB
  resources:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 2
      memory: 4Gi
  patroni:
    synchronous_mode: true
```

## Backup Strategy

| Database | Method | Frequency | Retention |
|----------|--------|-----------|-----------|
| PostgreSQL | pg_basebackup + WAL | Continuous | 30 days |
| MySQL | mysqldump + binlog | Daily + Continuous | 30 days |
| MongoDB | mongodump | Hourly | 14 days |
| Redis | RDB + AOF | Every 15 min | 7 days |

## Monitoring Metrics

Key metrics tracked for each database:
- Query latency (p50, p95, p99)
- Connections (active, idle, waiting)
- Replication lag
- Storage usage and IOPS
- Lock waits and deadlocks
- Slow query log
