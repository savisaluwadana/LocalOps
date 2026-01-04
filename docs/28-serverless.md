# Serverless and Event-Driven Architecture

## Table of Contents

1. [Serverless Concepts](#serverless-concepts)
2. [FaaS (Function as a Service)](#faas-function-as-a-service)
3. [Event-Driven Architecture](#event-driven-architecture)
4. [Event Brokers (Kafka, RabbitMQ, SQS)](#event-brokers)
5. [Serverless Patterns](#serverless-patterns)

---

## Serverless Concepts

**Serverless** is a cloud execution model where the cloud provider dynamically manages the allocation of machine resources. Pricing is based on the actual amount of resources consumed by an application, rather than on pre-purchased units of capacity.

### Characteristics

1.  **No Server Management**: No patching, OS updates, or provisioning.
2.  **Auto-scaling**: Scales from zero to thousands of parallel requests instantly.
3.  **Pay-per-use**: Pay only for compute time (ms) and memory used.
4.  **Event-driven**: Triggered by events (HTTP, DB change, file upload).

### The "Serverless Spectrum"

-   **Compute**: AWS Lambda, Google Cloud Functions, Azure Functions.
-   **Storage**: S3, GCS.
-   **Database**: DynamoDB, Firestore, Aurora Serverless.
-   **Integration**: API Gateway, EventBridge, SQS.
-   **Containers**: AWS Fargate, Google Cloud Run.

---

## FaaS (Function as a Service)

### How it Works

1.  **Event Source**: Something happens (API call, image upload).
2.  **Trigger**: Cloud provider spins up a micro-container.
3.  **Execution**: Your code (Function) runs.
4.  **Destruction**: Environment freezes or destroys (Cold Start potential).

### Cold Starts

The latency experienced when a new execution environment needs to be initialized.

**Mitigation:**
-   **Keep Warm**: Ping function regularly.
-   **Provisioned Concurrency**: Pay to keep N instances warm.
-   **Language Choice**: Go/Node/Python start faster than Java/C#.

### Limitations

-   **Execution Duration**: Usually capped (e.g., 15 mins for Lambda).
-   **Statelessness**: No local disk persistence between calls.
-   **Cold Starts**: Latency spikes.

---

## Event-Driven Architecture

In an EDA, services communicate by producing and consuming events (state changes) rather than direct synchronous API calls.

### Events vs Messages

-   **Message**: "Do this" (Command). Expects a result.
-   **Event**: "This happened" (Fact). Doesn't care who listens.

### Topology

**Producers** ──(Event)──▶ **Broker/Router** ──(Push/Pull)──▶ **Consumers**

---

## Event Brokers

Choosing the right broker is critical.

### 1. Queues (Point-to-Point)
**AWS SQS, RabbitMQ**
-   **Pattern**: Producer -> Queue -> One Consumer picks it up.
-   **Use Case**: Task offloading (e.g., image resizing), Load leveling.
-   **Guarantee**: Usually At-Least-Once.

### 2. Topics (Pub/Sub)
**AWS SNS, Google Pub/Sub**
-   **Pattern**: Producer -> Topic -> Fan-out to ALL Subscribers.
-   **Use Case**: Notifications (Email + SMS + Webhook).

### 3. Streams (Log-based)
**Apache Kafka, AWS Kinesis**
-   **Pattern**: Append-only log. Consumers read from specific "offsets".
-   **Use Case**: High throughput data pipeline, Event Sourcing, Analytics.
-   **Persistence**: Events persist for N days.

### Comparison

| Feature | SQS (Queue) | SNS (PubSub) | Kafka (Stream) |
|---------|-------------|--------------|----------------|
| **Consumption** | Competing consumers | Broadcast (Fan-out) | Partitioned consumer group |
| **Ordering** | Best effort (FIFO avail) | No | Strict per partition |
| **Persistence** | Until deleted | No (Fire/Forget) | Configurable retention |
| **Replay** | No | No | Yes (Rewind offset) |

---

## Serverless Patterns

### 1. Fan-Out Pattern

Execute parallel processing for a single event.

```
                  ┌────────────┐
             ┌───▶│ Lambda A   │ (Resize Thumbnail)
┌─────────┐  │    └────────────┘
│ S3      │──┤
│ Upload  │  │    ┌────────────┐
└─────────┘  ├───▶│ Lambda B   │ (Extract Metadata)
             │    └────────────┘
             │
             │    ┌────────────┐
             └───▶│ Lambda C   │ (Update DB)
                  └────────────┘
```

### 2. Queue-Based Load Leveling

Protect downstream systems (Database) from traffic spikes.

```
┌───────┐      ┌───────┐      ┌──────────┐      ┌──────────┐
│ API   │ ──▶  │  SQS  │ ──▶  │  Lambda  │ ──▶  │ Database │
│ GW    │      │ Queue │      │ (Worker) │      │          │
└───────┘      └───────┘      └──────────┘      └──────────┘
(100 TPS)      (Buffer)       (Processed at     (Safe Load)
                              10 TPS controlled
                              by concurrency)
```

### 3. Strangler Fig (Serverless Edition)

Migrate monolith endpoints one by one.

```
User ──▶ API Gateway ──┬──▶ /users ──▶ New Lambda Function
                       │
                       └──▶ /* ──▶ Legacy Monolith (ALB)
```

### 4. Choreography (Event Bridge)

Decoupled microservices via a central bus.

```
Order Service ──(OrderConfigured)──▶ EventBridge
                                        │
                    ┌───────────────────┴───────────────────┐
                    ▼                                       ▼
             Shipping Service                        Invoice Service
```

### 5. Claim Check Pattern

Events should be small. Store large payload in DB/S3, pass ID in event.

```
Producer ──▶ [Store Payload in S3] ──▶ [Send Event {url: s3://...}]
                                                │
Consumer ◀── [Retrieve Payload] ◀── [Read Event]
```
