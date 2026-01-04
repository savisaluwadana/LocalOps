# Database Internals for SREs

## Table of Contents
1.  [Storage Engines: B-Trees vs LSM Trees](#storage-engines-b-trees-vs-lsm-trees)
2.  [Transactions & Isolation Levels](#transactions--isolation-levels)
3.  [Sharding Strategies](#sharding-strategies)
4.  [Replication Internals](#replication-internals)
5.  [The Write Ahead Log (WAL)](#the-write-ahead-log-wal)

---

## Storage Engines: B-Trees vs LSM Trees

The most fundamental design decision in a database is how it stores data on disk.

### 1. B-Trees (Read Optimized)
**Used by**: PostgreSQL, MySQL (InnoDB), Oracle.
-   **Structure**: Sorted tree structure. Data is stored in fixed-size pages (e.g., 8KB).
-   **Read**: `O(log N)`. Very fast. Just traverse the tree pointers.
-   **Write**: Slower. Random I/O. Inserting a key might require "rebalancing" the tree and moving pages around.
-   **Use Case**: General purpose, Read-heavy, ACID transactional workloads.

### 2. LSM Trees (Write Optimized)
**Used by**: Cassandra, RocksDB, LevelDB, InfluxDB.
-   **Structure**: Log-Structured Merge Tree.
    1.  **MemTable**: Writes go to in-memory buffer (Sorted Map).
    2.  **SSTable**: When MemTable fills, it's flushed to disk as an immutable Sorted String Table.
    3.  **Compaction**: Background process merges many small SSTables into larger ones.
-   **Write**: `O(1)`. Append-only. Extremely fast.
-   **Read**: Slower. Must check MemTable + all SSTables on disk ( Bloom Filters used to speed this up).
-   **Use Case**: High-velocity ingestion (Logs, Metrics, IoT).

---

## Transactions & Isolation Levels

"ACID" is a spectrum. The "I" (Isolation) determines potential bugs.

| Isolation Level | Dirty Read? | Non-Repeatable Read? | Phantom Read? | Perf Cost |
|-----------------|-------------|----------------------|---------------|-----------|
| **Read Uncommitted** | Yes | Yes | Yes | Low |
| **Read Committed** | No | Yes | Yes | Low (Default PG) |
| **Repeatable Read** | No | No | Yes | Medium (Default MySQL) |
| **Serializable** | No | No | No | High (Locking) |

### Anomalies Explained
-   **Dirty Read**: Reading data that wasn't committed (and might be rolled back).
-   **Non-Repeatable Read**: Querying `SELECT * FROM users WHERE id=1` twice in a transaction gets different results.
-   **Phantom Read**: `SELECT count(*)` returns 5, then 6. (New row inserted by other TX).

---

## Sharding Strategies

When one node isn't enough, we split data.

### 1. Key-Based (Hash) Sharding
`Shard_ID = hash(Key) % Num_Shards`
-   **Pros**: Even distribution.
-   **Cons**: Resharding is painful. If `Num_Shards` changes from 10 to 11, *almost all* keys move.
-   **Fix**: **Consistent Hashing** (Ring topology). Only K/N keys move.

### 2. Range-Based Sharding
`Shard_A = [A-M]`, `Shard_B = [N-Z]`
-   **Pros**: Efficient Range Scans (`SELECT * WHERE name LIKE 'A%'`).
-   **Cons**: Hotspots. If everyone inserts names starting with 'A', Shard_A melts while Shard_B is idle.

### 3. Directory-Based Sharding
Lookup table: `Key -> Shard_ID`.
-   **Pros**: Total flexibility.
-   **Cons**: Lookup table becomes the bottleneck (Single point of failure).

---

## Replication Internals

### Synchronous vs Asynchronous
-   **Sync**: Primary waits for Replica to ACK. Safe, but latency penalty.
-   **Async**: Primary returns immediately. Fast, but data loss possible if Primary dies before replication.

### Replication Lag Issues
If user writes to Primary and immediately reads from Replica, they might get 404.
**Fixes**:
1.  **Read-Your-Writes Consistency**: Sticky sessions pin user to Primary for N seconds after a write.
2.  **Monotonic Reads**: Ensure user never sees time go backwards (don't route to lagging replica).

---

## The Write Ahead Log (WAL)

How do databases survive power failure?

1.  **The Rule**: Never modify data pages in memory without first appending the action to the WAL on disk.
2.  **fsync()**: Syscall that forces flush from OS cache to Physical Disk.
3.  **Crash Recovery**: On reboot, DB reads WAL and "replays" events to restore memory state.

**Database vs File System**:
Databases often bypass OS Cache (`O_DIRECT`) to control exactly when data hits the disk, avoiding "Partial Page Writes" (Torn pages).
