# Database Management for DevOps Complete Guide

## Table of Contents

1. [Database Fundamentals](#database-fundamentals)
2. [SQL vs NoSQL](#sql-vs-nosql)
3. [PostgreSQL](#postgresql)
4. [MongoDB](#mongodb)
5. [Redis](#redis)
6. [Database in Kubernetes](#database-in-kubernetes)
7. [Backup and Recovery](#backup-and-recovery)
8. [High Availability](#high-availability)
9. [Best Practices](#best-practices)

---

## Database Fundamentals

### Database Types

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      DATABASE CATEGORIES                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   RELATIONAL (SQL)                                                       │
│   ├── PostgreSQL, MySQL, MariaDB                                        │
│   ├── Structured data with relationships                                │
│   ├── ACID transactions                                                 │
│   └── Best for: Financial, e-commerce, traditional apps                │
│                                                                          │
│   DOCUMENT (NoSQL)                                                       │
│   ├── MongoDB, CouchDB                                                  │
│   ├── JSON-like documents                                               │
│   ├── Flexible schema                                                   │
│   └── Best for: Content management, catalogs, user profiles            │
│                                                                          │
│   KEY-VALUE                                                              │
│   ├── Redis, Memcached, etcd                                            │
│   ├── Simple key-value pairs                                            │
│   ├── Extremely fast                                                    │
│   └── Best for: Caching, sessions, real-time data                       │
│                                                                          │
│   TIME-SERIES                                                            │
│   ├── InfluxDB, TimescaleDB, Prometheus                                 │
│   ├── Optimized for time-stamped data                                   │
│   └── Best for: Metrics, IoT, monitoring                                │
│                                                                          │
│   GRAPH                                                                  │
│   ├── Neo4j, Amazon Neptune                                             │
│   ├── Nodes and relationships                                           │
│   └── Best for: Social networks, recommendations, fraud detection      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## SQL vs NoSQL

### Comparison

| Aspect | SQL | NoSQL |
|--------|-----|-------|
| Schema | Fixed (rigid) | Flexible (dynamic) |
| Relationships | JOINs | Embedded/references |
| Scaling | Vertical (scale up) | Horizontal (scale out) |
| Transactions | Strong ACID | Eventual consistency |
| Query Language | SQL | Varies by database |
| Best for | Complex queries | Simple, high-volume |

### ACID vs BASE

**ACID (SQL):**
- **A**tomicity - All or nothing
- **C**onsistency - Valid state only
- **I**solation - Concurrent safety
- **D**urability - Persisted forever

**BASE (NoSQL):**
- **B**asically **A**vailable - Always responds
- **S**oft state - May change over time
- **E**ventual consistency - Will be consistent eventually

---

## PostgreSQL

### Why PostgreSQL?

- Advanced features (JSONB, arrays, full-text search)
- Excellent performance
- Strong consistency
- Extensive extension ecosystem

### Docker Deployment

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: myapp_production
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myapp"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

### Essential Commands

```bash
# Connect
psql -h localhost -U myapp -d myapp_production

# Backup
pg_dump -h localhost -U myapp myapp_production > backup.sql

# Restore
psql -h localhost -U myapp myapp_production < backup.sql

# List databases
\l

# List tables
\dt

# Describe table
\d tablename
```

---

## MongoDB

### Why MongoDB?

- Flexible schema
- JSON-native
- Horizontal scaling (sharding)
- Rich query language

### Docker Deployment

```yaml
version: '3.8'
services:
  mongodb:
    image: mongo:6
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongo_data:/data/db
    ports:
      - "27017:27017"
    command: --wiredTigerCacheSizeGB 1.5

volumes:
  mongo_data:
```

### Essential Commands

```javascript
// Connect
mongosh "mongodb://admin:password@localhost:27017"

// Show databases
show dbs

// Use database
use myapp

// Find documents
db.users.find({ active: true })

// Insert
db.users.insertOne({ name: "John", email: "john@example.com" })

// Update
db.users.updateOne({ _id: id }, { $set: { active: false } })
```

---

## Redis

### Why Redis?

- In-memory (extremely fast)
- Data structures (strings, lists, sets, hashes)
- Pub/sub messaging
- TTL support

### Use Cases

| Use Case | Pattern |
|----------|---------|
| Caching | Store frequently accessed data |
| Sessions | User session storage |
| Rate limiting | Count requests per time window |
| Queues | Job/task queues |
| Real-time | Pub/sub for live updates |

### Docker Deployment

```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"

volumes:
  redis_data:
```

### Essential Commands

```bash
# Connect
redis-cli -h localhost -a password

# Set/Get
SET mykey "Hello"
GET mykey

# Set with TTL (1 hour)
SETEX session:123 3600 "user_data"

# Lists
LPUSH myqueue "item1"
RPOP myqueue

# Hashes
HSET user:1 name "John" email "john@example.com"
HGETALL user:1
```

---

## Database in Kubernetes

### StatefulSet for Databases

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15
          ports:
            - containerPort: 5432
          envFrom:
            - secretRef:
                name: postgres-secret
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
```

### Operators

Use operators for production databases:

| Database | Operator |
|----------|----------|
| PostgreSQL | CloudNativePG, Crunchy |
| MongoDB | MongoDB Community Operator |
| MySQL | Oracle MySQL Operator |
| Redis | Redis Operator |

---

## Backup and Recovery

### Backup Strategy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      BACKUP STRATEGY                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   FULL BACKUP                                                            │
│   • Complete database copy                                              │
│   • Weekly or monthly                                                   │
│   • Large storage, slow to create                                       │
│                                                                          │
│   INCREMENTAL BACKUP                                                     │
│   • Only changes since last backup                                      │
│   • Daily or more frequent                                              │
│   • Small, fast, requires full to restore                               │
│                                                                          │
│   CONTINUOUS (WAL/PITR)                                                  │
│   • Stream transaction logs                                             │
│   • Point-in-time recovery                                              │
│   • Minimal data loss                                                   │
│                                                                          │
│   Recommended: Full weekly + incremental daily + continuous WAL         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Backup Locations

- Same region storage (fast recovery)
- Cross-region storage (disaster recovery)
- Off-site/cloud (complete disaster)

---

## High Availability

### Replication Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| Primary-Replica | One writer, many readers | Read-heavy workloads |
| Primary-Primary | Multiple writers | Geographic distribution |
| Synchronous | Waits for replica | Zero data loss |
| Asynchronous | Non-blocking | Low latency |

### PostgreSQL HA

```yaml
# Patroni cluster for PostgreSQL HA
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: production-db
spec:
  teamId: "myteam"
  numberOfInstances: 3
  users:
    myapp: []
  databases:
    myapp: myapp
  postgresql:
    version: "15"
  volume:
    size: 50Gi
```

---

## Best Practices

### Security

1. **Use strong passwords** - Generated, not human-memorable
2. **Network isolation** - Database not publicly accessible
3. **Encrypt at rest** - Storage encryption
4. **Encrypt in transit** - TLS connections
5. **Least privilege** - App-specific credentials

### Performance

1. **Index appropriately** - Based on query patterns
2. **Connection pooling** - PgBouncer, ProxySQL
3. **Query optimization** - EXPLAIN ANALYZE
4. **Resource limits** - Memory, connections
5. **Monitoring** - Slow queries, connections, storage

### Operations

1. **Test restores** - Backups are useless if you can't restore
2. **Monitor replication lag** - Catch issues early
3. **Plan for scaling** - Vertical or horizontal
4. **Document runbooks** - Failover procedures
5. **Regular maintenance** - VACUUM, ANALYZE

This guide covers database management essentials for DevOps with practical examples and operational best practices.
