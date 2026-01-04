# Event Streaming Platform

Apache Kafka-based event streaming.

## Features

- **Producers/Consumers** - Publish and subscribe
- **Topics** - Partitioned event logs
- **Consumer Groups** - Parallel processing
- **Schema Registry** - Avro/JSON schemas
- **KSQL** - Stream processing SQL
- **Kafka UI** - Visual management

## Quick Start

```bash
docker compose up -d

# Kafka UI: http://localhost:8080
# Schema Registry: http://localhost:8081

# Create topic
docker compose exec kafka kafka-topics --create \
  --topic orders --partitions 3 --replication-factor 1 \
  --bootstrap-server localhost:9092

# Produce message
docker compose exec kafka kafka-console-producer \
  --topic orders --bootstrap-server localhost:9092
```
