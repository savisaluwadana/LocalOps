# System Design for Cloud Infrastructure

## Table of Contents
1.  [Designing for Availability (99.999%)](#designing-for-availability)
2.  [Multi-Region Architectures](#multi-region-architectures)
3.  [Resiliency Patterns](#resiliency-patterns)
4.  [Scaling Strategies](#scaling-strategies)
5.  [Disaster Recovery (RTO/RPO)](#disaster-recovery)

---

## Designing for Availability

Availability = `(Uptime / Total Time) * 100`.

| Nines | Availability | Downtime/Year | Example Arch |
|-------|--------------|---------------|--------------|
| **99.9%** | "Three Nines" | ~9 hours | Single Region, Multi-AZ |
| **99.99%** | "Four Nines" | ~52 mins | Multi-Region Active/Passive |
| **99.999%**| "Five Nines" | ~5 mins | Multi-Region Active/Active |

### Calculated Availability
If Service A (99.9%) depends on Service B (99.9%):
Total Availability = `0.999 * 0.999` = `99.8%`. **Dependencies reduce availability.**

---

## Multi-Region Architectures

### 1. Active-Passive (Warm Standby)
Traffic goes to `us-east-1`. `us-west-1` has a scaled-down copy running (Database replicating async).
-   **Failover**: Manual or DNS update (R53 Healthcheck).
-   **RIO**: Minutes. **RPO**: Seconds (Replication lag).
-   **Cost**: x1.5 (Warm standby cost).

### 2. Active-Active (Global)
Traffic goes to both `us-east-1` and `us-west-1` simultaneously.
-   **Database**: Needs Multi-Master (e.g., DynamoDB Global Tables, CockroachDB).
-   **Latency**: Users routed to nearest region (GeoDNS).
-   **Complexity**: Extremely High. Data conflicts possible.
-   **Cost**: x2.

---

## Resiliency Patterns

How to prevent "cascading failure" (One service killing the whole platform).

### 1. Circuit Breaker
If Service B fails 5 times, Service A stops calling it and returns default/error immediately.
-   **States**: Closed (Normal) -> Open (Error) -> Half-Open (Test).

### 2. Bulkhead Pattern
Isolate resources.
-   *Analogy*: Ship compartments. If one floods, ship floats.
-   *Implementation*: Thread pools per dependency. If "ImageService" hangs, it consumes internal "ImageThreads". "LoginThreads" are unaffected.

### 3. Shuffle Sharding
Limiting the "Blast Radius".
Instead of 1000 customers sharing 10 servers, assign each customer a random pair (e.g., Server 1 and 4).
-   If Server 1 dies, only customers on (1, *) are affected, not everyone.

---

## Scaling Strategies

### Load Shedding
"I am full. Go away."
Better to serve 90% of users successfully than 100% of users slowly (ultimately failing all).
-   **Implementation**: Reject (HTTP 503) if CPU > 80% or Queue > 1000.

### Backpressure
"Stop sending me data."
Consumer tells Producer to slow down.
-   **TCP**: Window size scaling.
-   **Reactive Streams**: Explicit `request(n)` signals.

### Caching Strategy
-   **Look-aside**: Code checks Cache -> DB.
-   **Write-through**: Code writes to Cache, Cache writes to DB. (Slow write, fast read).
-   **Write-back**: Code writes to Cache, Cache async writes to DB. (Fast write, risk of data loss).
-   **Thundering Herd**: 1000 users ask for same Key, Key missing, 1000 DB hits.
    -   *Fix*: Request Coalescing (Wait and grouping).

---

## Disaster Recovery (RTO/RPO)

Business metrics, not tech components.

-   **RTO (Recovery Time Objective)**: "How long can we be down?" (e.g., 4 hours).
-   **RPO (Recovery Point Objective)**: "How much data can we lose?" (e.g., 15 minutes).

### Tiers
| Tier | Architecture | RTO | RPO |
|------|--------------|-----|-----|
| **Backup & Restore** | S3 Backups | 24h | 24h |
| **Pilot Light** | DB On, App Off in DR Region | 4h | 1h |
| **Warm Standby** | Scaled down App in DR | 1h | 5m |
| **Multi-Site Active** | 100% Traffic split | 0m | 0m |
