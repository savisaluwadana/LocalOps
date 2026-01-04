# Data Pipeline Platform

Enterprise data pipeline with Airflow, Spark, dbt, and streaming.

## Architecture

- **Ingestion** - Airbyte, Debezium CDC, Kafka Connect
- **Data Lake** - Delta Lake (Bronze/Silver/Gold layers)
- **Processing** - Apache Spark, Apache Flink
- **Transformations** - dbt for SQL-based transforms
- **Orchestration** - Apache Airflow

## Quick Start

```bash
kubectl apply -k kubernetes/base
helm install airflow apache-airflow/airflow
```

## SLAs

| Pipeline | Schedule | SLA |
|----------|----------|-----|
| Daily ETL | 2:00 AM | 4 hours |
| Hourly | Every hour | 30 min |
| Real-time | Continuous | 5 min |
