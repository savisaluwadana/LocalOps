# Log Aggregation Stack

Complete logging solution with Elasticsearch, Logstash, and Kibana (ELK Stack).

## Architecture

```
Application → Logstash → Elasticsearch → Kibana
   logs        parse       store          visualize
```

## Quick Start

```bash
docker compose up -d

# Wait for Elasticsearch to be ready (1-2 minutes)
curl http://localhost:9200/_cluster/health

# Access Kibana
open http://localhost:5601

# Send test log
echo '{"message":"Test log","level":"info"}' | nc localhost 5000
```

## Components

| Service | Port | Purpose |
|---------|------|---------|
| Elasticsearch | 9200 | Store & search logs |
| Kibana | 5601 | Visualization |
| Logstash | 5000 | Log ingestion |

## Sample Application

The included sample app generates logs automatically:
```bash
curl http://localhost:8080/generate-logs
```
