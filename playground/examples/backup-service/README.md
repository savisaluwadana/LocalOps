# Backup Service

Automated backup solution for databases and files.

## Features

- **Scheduled Backups** - Cron-based scheduling
- **Multiple Targets** - PostgreSQL, MySQL, MongoDB, files
- **Storage Backends** - S3, MinIO, local
- **Encryption** - AES-256 encrypted backups
- **Retention** - Configurable retention policies
- **Notifications** - Slack/email on success/failure
- **Restore** - Easy point-in-time recovery

## Quick Start

```bash
docker compose up -d

# Manual backup
curl -X POST http://localhost:8000/api/backup/trigger \
  -H "Content-Type: application/json" \
  -d '{"source": "postgres", "name": "mydb"}'

# List backups
curl http://localhost:8000/api/backups

# Restore
curl -X POST http://localhost:8000/api/backup/restore \
  -d '{"backup_id": "backup-123"}'
```

## Configuration

```yaml
backups:
  - name: production-db
    source: postgres
    connection: postgres://user:pass@host/db
    schedule: "0 2 * * *"  # Daily at 2 AM
    retention:
      daily: 7
      weekly: 4
      monthly: 3
    storage: s3://backups/postgres
```
