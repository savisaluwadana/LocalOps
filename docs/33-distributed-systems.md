# Distributed Systems Theory Deep Dive

## Table of Contents
1.  [Time & Clocks: The Root of All Evil](#time--clocks-the-root-of-all-evil)
2.  [Consistency Models: The Hierarchy](#consistency-models-the-hierarchy)
3.  [Consensus: Multi-Paxos & Raft](#consensus-multi-paxos--raft)
4.  [Transactions: 2PC vs Sagas](#transactions-2pc-vs-sagas)
5.  [Failure Detectors & Gossip Protocols](#failure-detectors--gossip-protocols)

---

## Time & Clocks: The Root of All Evil

In a centralized system, `Time.now()` is truth. In distributed systems, it's an estimation.

### The Problem with Physical Clocks
Quartz crystals drift. NTP corrects them, but steps backwards.
-   **Drift**: ~17 seconds per day worst case.
-   **Leap Seconds**: Can cause cascading failures (e.g., Cloudflare DNS outage 2017).

### Logical Clocks
If we can't trust time, we trust **Causality**.

#### 1. Lamport Clocks
Simple counter passed with messages.
-   `A` sends msg with `Time=1`.
-   `B` receives, sets `Time = max(Local, Msg) + 1`.
-   **Limit**: Tells us simple partial ordering. If `L(a) < L(b)`, we don't know if causal or concurrent.

#### 2. Vector Clocks
Array of counters `[A:1, B:0, C:2]`.
-   Used by **Amazon Dynamo / Riak** to detect **conflicting writes** (siblings).
-   If `V1 < V2` (for all elements), then V1 happened before V2.
-   If mixed (V1[A] > V2[A] BUT V1[B] < V2[B]), then **Concurrent Update**. Application must resolve (e.g., "Merge shopping cart").

---

## Consistency Models: The Hierarchy

Developers confuse ACID Consistency (Database rules) with CAP Consistency (Atomic reads).

### 1. Linearizability (Atomic Consistency)
The gold standard.
-   Once a write completes, all future reads return that value.
-   Network delay makes this slow (Speed of Light).
-   Examples: **etcd**, **Zookeeper**, **Google Spanner**.

### 2. Sequential Consistency
Everyone sees updates in the *same order*, but maybe not real-time.
-   Example: Your Facebook feed might be 5s stale, but comments appear in order.

### 3. Causal Consistency
Preserves cause-and-effect.
-   If I reply to a comment, my reply must not appear before the comment.
-   Unrelated events can be out of order.
-   Example: **CosmosDB (Session Consistency)**.

### 4. Eventual Consistency
"Stop writing, and eventually we agree."
-   Read-Your-Writes: I see my changes immediately.
-   Monotonic Read: I never see older data than what I saw before.
-   Examples: **DNS**, **Cassandra**, **S3** (previously).

---

## Consensus: Multi-Paxos & Raft

How to agree on a sequence of values in presence of failures.

### The Raft Algorithm (Simplified)

Raft solves consensus by electing a strong Leader.

#### 1. Leader Election
-   Each node has a random **Election Timeout** (150-300ms).
-   Node times out -> Becomes **Candidate** -> Votes for self -> Requests votes.
-   Other nodes vote for first request in that term.
-   Majority (N/2+1)? Become **Leader**.

#### 2. Log Replication
-   Client sends command `SET X=5`.
-   Leader appends to local log (Uncommitted).
-   Leader sends `AppendEntries` to followers.
-   Followers append and Ack.
-   Leader gets Majority Acks? **Commit** -> Execute -> Reply to client.
-   Leader tells followers to Commit.

#### 3. Safety Property
-   Raft ensures a node cannot be elected leader if it misses committed entries. "Log Matching Property".

---

## Transactions: 2PC vs Sagas

How to do a transaction across Service A (Payment) and Service B (Shipping)?

### 1. Two-Phase Commit (2PC)
The "Traditional" way (XA Transactions).
-   **Phase 1 (Prepare)**: Coordinator asks A and B "Can you commit?". A/B lock rows.
-   **Phase 2 (Commit)**: Coordinator says "Commit!".
-   **Problem**: Blocking. If Coordinator dies after locking, A and B wait forever. **Not recommended for Microservices.**

### 2. The Saga Pattern (Long-Running Transactions)
Sequence of local transactions.
-   Step 1: Payment Service (Local TX: Charge Card). Success event.
-   Step 2: Shipping Service (Local TX: Ship Item). Fails?
-   **Compensation**: Shipping Service emits "Fail".
-   Step 3: Payment Service listens, runs **Undo Transaction** (Refund Card).

*Tradeoff*: No isolation. User might see "Charged" then "Refunded".

---

## Failure Detectors & Gossip Protocols

How do I know a node is dead?

### Heartbeating
-   Ping every 1s. No pong for 5s? Dead.
-   **Problem**: Flaky network = False Positives.

### Phi Accrual Failure Detector (Cassandra)
-   Don't return boolean (Up/Down).
-   Return **Probability** (Phi) that node is down based on history of inter-arrival times.
-   Adapts to slow networks automatically.

### Gossip Protocol (SWIM / Serf)
-   Used by **Consul**.
-   Node A picks random Node B. Sends "Ping".
-   If no ack, A asks Nodes C/D to "Ping-req B".
-   If C/D succeed, B is alive (A has bad path).
-   If C/D fail, B is marked dead.
-   *Scales O(log N)*.
