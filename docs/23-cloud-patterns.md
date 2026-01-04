# Cloud Architecture Patterns

Enterprise cloud architecture patterns for building scalable, resilient, and secure systems.

## Table of Contents

1. [Microservices Patterns](#microservices-patterns)
2. [Data Patterns](#data-patterns)
3. [Resilience Patterns](#resilience-patterns)
4. [Security Patterns](#security-patterns)
5. [Messaging Patterns](#messaging-patterns)
6. [Deployment Patterns](#deployment-patterns)

---

## Microservices Patterns

### Service Decomposition

#### Domain-Driven Design (DDD)

**Bounded Context:** A logical boundary containing a domain model.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        E-COMMERCE DOMAIN                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐ │
│  │   ORDER CONTEXT   │   │ INVENTORY CONTEXT │   │ CUSTOMER CONTEXT  │ │
│  │                   │   │                   │   │                   │ │
│  │  • Order          │   │  • Product        │   │  • Customer       │ │
│  │  • OrderItem      │   │  • Stock          │   │  • Address        │ │
│  │  • Payment        │   │  • Warehouse      │   │  • Preferences    │ │
│  │                   │   │                   │   │                   │ │
│  │  Order Service    │   │ Inventory Service │   │ Customer Service  │ │
│  └───────────────────┘   └───────────────────┘   └───────────────────┘ │
│           │                       │                       │             │
│           └───────────────────────┼───────────────────────┘             │
│                                   │                                      │
│                          Integration Events                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Ubiquitous Language:**
- Same terms used by developers and domain experts
- Encapsulated within bounded context
- Different contexts may have different meanings for same term

### API Gateway Pattern

```
┌────────────────────────────────────────────────────────────────────────┐
│                          API GATEWAY                                    │
│                                                                         │
│  ┌─────────┐                                                           │
│  │ Mobile  │ ─────┐                                                    │
│  │  App    │      │     ┌──────────────────────────────────────────┐  │
│  └─────────┘      │     │           API Gateway                     │  │
│                   │     │  ┌─────────────────────────────────────┐ │  │
│  ┌─────────┐      ├────▶│  │ • Authentication & Authorization    │ │  │
│  │   Web   │ ─────┤     │  │ • Rate Limiting                     │ │  │
│  │   App   │      │     │  │ • Request Routing                   │ │  │
│  └─────────┘      │     │  │ • Load Balancing                    │ │  │
│                   │     │  │ • Request/Response Transformation   │ │  │
│  ┌─────────┐      │     │  │ • Caching                           │ │  │
│  │ Partner │ ─────┘     │  │ • SSL Termination                   │ │  │
│  │   API   │            │  │ • API Versioning                    │ │  │
│  └─────────┘            │  └─────────────────────────────────────┘ │  │
│                         └──────────────────────────────────────────┘  │
│                                         │                              │
│                    ┌────────────────────┼────────────────────┐        │
│                    ▼                    ▼                    ▼        │
│             ┌───────────┐        ┌───────────┐        ┌───────────┐  │
│             │  User     │        │  Order    │        │  Product  │  │
│             │  Service  │        │  Service  │        │  Service  │  │
│             └───────────┘        └───────────┘        └───────────┘  │
│                                                                       │
└────────────────────────────────────────────────────────────────────────┘
```

**Implementations:**
- Kong, AWS API Gateway, Azure API Management
- Nginx, Envoy, Traefik
- Netflix Zuul, Spring Cloud Gateway

### Backend for Frontend (BFF)

```
┌────────────────────────────────────────────────────────────────────────┐
│                     BACKEND FOR FRONTEND (BFF)                          │
│                                                                         │
│  ┌─────────────┐     ┌──────────────┐                                  │
│  │   Mobile    │────▶│  Mobile BFF  │────┐                             │
│  │    App      │     │  (REST)      │    │                             │
│  └─────────────┘     └──────────────┘    │                             │
│                                          │                              │
│  ┌─────────────┐     ┌──────────────┐    │    ┌──────────────────────┐│
│  │    Web      │────▶│   Web BFF    │────┼───▶│   Microservices      ││
│  │    App      │     │  (GraphQL)   │    │    │                      ││
│  └─────────────┘     └──────────────┘    │    │  • User Service      ││
│                                          │    │  • Order Service     ││
│  ┌─────────────┐     ┌──────────────┐    │    │  • Product Service   ││
│  │    IoT      │────▶│   IoT BFF    │────┘    │  • Payment Service   ││
│  │  Devices    │     │  (MQTT)      │         │                      ││
│  └─────────────┘     └──────────────┘         └──────────────────────┘│
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

**Benefits:**
- Optimized payloads per client
- Client-specific auth/caching
- Independent deployment
- Reduced client complexity

### Service Mesh

```
┌────────────────────────────────────────────────────────────────────────┐
│                          SERVICE MESH                                   │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                      CONTROL PLANE                               │  │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │
│   │  │    Pilot    │  │   Citadel   │  │   Galley    │              │  │
│   │  │  (Config)   │  │   (Certs)   │  │ (Validation)│              │  │
│   │  └─────────────┘  └─────────────┘  └─────────────┘              │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                   │                                     │
│                    ┌──────────────┼──────────────┐                     │
│                    ▼              ▼              ▼                     │
│   ┌────────────────────┐  ┌────────────────────┐                      │
│   │   Pod A            │  │   Pod B            │                      │
│   │  ┌──────────────┐  │  │  ┌──────────────┐  │                      │
│   │  │  Application │  │  │  │  Application │  │                      │
│   │  └───────┬──────┘  │  │  └───────┬──────┘  │                      │
│   │          │         │  │          │         │                      │
│   │  ┌───────▼──────┐  │  │  ┌───────▼──────┐  │                      │
│   │  │ Envoy Proxy  │◀─┼──┼─▶│ Envoy Proxy  │  │                      │
│   │  │  (Sidecar)   │  │  │  │  (Sidecar)   │  │                      │
│   │  └──────────────┘  │  │  └──────────────┘  │                      │
│   └────────────────────┘  └────────────────────┘                      │
│                                                                         │
│   Features: mTLS, Traffic Management, Observability, Fault Injection   │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

**Implementations:** Istio, Linkerd, Consul Connect

---

## Data Patterns

### Database per Service

```
┌────────────────────────────────────────────────────────────────────────┐
│                      DATABASE PER SERVICE                               │
│                                                                         │
│   ┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐│
│   │   Order Service   │   │  Product Service  │   │ Customer Service  ││
│   └─────────┬─────────┘   └─────────┬─────────┘   └─────────┬─────────┘│
│             │                       │                       │          │
│             ▼                       ▼                       ▼          │
│   ┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐│
│   │   PostgreSQL      │   │   MongoDB         │   │   MySQL           ││
│   │   (Orders DB)     │   │   (Products DB)   │   │   (Customers DB)  ││
│   └───────────────────┘   └───────────────────┘   └───────────────────┘│
│                                                                         │
│   Benefits:                                                             │
│   • Loose coupling            • Independent scaling                    │
│   • Data isolation            • Polyglot persistence                   │
│                                                                         │
│   Challenges:                                                           │
│   • Distributed transactions  • Data consistency                       │
│   • Join queries across DBs   • Increased complexity                   │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Saga Pattern

For distributed transactions across services:

#### Choreography-Based Saga

```
┌────────────────────────────────────────────────────────────────────────┐
│                    CHOREOGRAPHY SAGA                                    │
│                                                                         │
│   Order Service ──[OrderCreated]──▶ Payment Service                    │
│                                           │                             │
│                                    [PaymentCompleted]                   │
│                                           │                             │
│                                           ▼                             │
│                                    Inventory Service                    │
│                                           │                             │
│                                    [InventoryReserved]                  │
│                                           │                             │
│                                           ▼                             │
│                                    Shipping Service                     │
│                                           │                             │
│                                    [OrderShipped]                       │
│                                           │                             │
│                                           ▼                             │
│                                    Order Service                        │
│                                    (Update Status)                      │
│                                                                         │
│   Compensation (Rollback):                                              │
│   PaymentFailed ──▶ CancelOrder                                        │
│   InventoryFailed ──▶ RefundPayment ──▶ CancelOrder                    │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

#### Orchestration-Based Saga

```
┌────────────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATION SAGA                                   │
│                                                                         │
│                    ┌──────────────────────────┐                        │
│                    │    SAGA ORCHESTRATOR     │                        │
│                    │    (Order Saga)          │                        │
│                    └────────────┬─────────────┘                        │
│                                 │                                       │
│         ┌───────────────────────┼───────────────────────┐              │
│         │                       │                       │              │
│         ▼                       ▼                       ▼              │
│   ┌───────────┐          ┌───────────┐          ┌───────────┐         │
│   │  Payment  │          │ Inventory │          │ Shipping  │         │
│   │  Service  │          │  Service  │          │  Service  │         │
│   └───────────┘          └───────────┘          └───────────┘         │
│                                                                         │
│   Orchestrator Controls:                                                │
│   1. Create Order                                                       │
│   2. Reserve Inventory                                                  │
│   3. Process Payment                                                    │
│   4. Initiate Shipping                                                  │
│   5. Complete Order                                                     │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### CQRS (Command Query Responsibility Segregation)

```
┌────────────────────────────────────────────────────────────────────────┐
│                              CQRS                                       │
│                                                                         │
│                    ┌─────────────────────────┐                         │
│                    │        Commands         │                         │
│    Write ─────────▶│  Create, Update, Delete │                         │
│    Operations      └────────────┬────────────┘                         │
│                                 │                                       │
│                                 ▼                                       │
│                    ┌─────────────────────────┐                         │
│                    │     Write Model         │                         │
│                    │    (Normalized DB)      │                         │
│                    └────────────┬────────────┘                         │
│                                 │                                       │
│                          Domain Events                                  │
│                                 │                                       │
│                                 ▼                                       │
│                    ┌─────────────────────────┐                         │
│                    │     Read Model          │                         │
│                    │ (Optimized for queries) │                         │
│                    └────────────┬────────────┘                         │
│                                 │                                       │
│                    ┌────────────▼────────────┐                         │
│                    │        Queries          │                         │
│    Read ◀──────────│   Materialized Views   │                         │
│    Operations      └─────────────────────────┘                         │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Event Sourcing

```
┌────────────────────────────────────────────────────────────────────────┐
│                        EVENT SOURCING                                   │
│                                                                         │
│   Traditional:  Current State = Last Update                            │
│                                                                         │
│   Event Sourcing: Current State = Σ (All Events)                       │
│                                                                         │
│   Event Store:                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │ ID  │ Aggregate │ Type              │ Data              │ Time  │  │
│   ├─────┼───────────┼───────────────────┼───────────────────┼───────┤  │
│   │  1  │ Order-123 │ OrderCreated      │ {customer: "A"}   │ 10:00 │  │
│   │  2  │ Order-123 │ ItemAdded         │ {sku: "P1", qty:2}│ 10:01 │  │
│   │  3  │ Order-123 │ ItemAdded         │ {sku: "P2", qty:1}│ 10:02 │  │
│   │  4  │ Order-123 │ PaymentReceived   │ {amount: 150}     │ 10:05 │  │
│   │  5  │ Order-123 │ OrderShipped      │ {tracking: "XYZ"} │ 10:30 │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│   Benefits:                                                             │
│   • Complete audit trail          • Temporal queries                   │
│   • Replay events for debugging   • Event-driven architecture          │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Resilience Patterns

### Circuit Breaker

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CIRCUIT BREAKER                                  │
│                                                                         │
│   States:                                                               │
│                                                                         │
│   ┌────────────┐         ┌────────────┐         ┌────────────┐         │
│   │   CLOSED   │         │    OPEN    │         │ HALF-OPEN  │         │
│   │            │         │            │         │            │         │
│   │  Requests  │  Fail   │  Requests  │  Timer  │   Test     │         │
│   │   Pass     │  ──────▶│   Fail     │  ──────▶│  Requests  │         │
│   │  Through   │ Threshold│  Fast     │ Expires │            │         │
│   │            │         │            │         │            │         │
│   └──────┬─────┘         └────────────┘         └──────┬─────┘         │
│          │                      ▲                      │               │
│          │                      │    Success           │               │
│          │                      └──────────────────────┘               │
│          │                             Fail                             │
│          └─────────────────────────────┘                               │
│                                                                         │
│   Configuration:                                                        │
│   • Failure threshold: 5 failures                                      │
│   • Timeout: 30 seconds                                                │
│   • Half-open requests: 3                                              │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Retry with Exponential Backoff

```
┌────────────────────────────────────────────────────────────────────────┐
│                    EXPONENTIAL BACKOFF                                  │
│                                                                         │
│   Attempt 1: Wait 1 second                                             │
│   Attempt 2: Wait 2 seconds                                            │
│   Attempt 3: Wait 4 seconds                                            │
│   Attempt 4: Wait 8 seconds                                            │
│   Attempt 5: Wait 16 seconds (max)                                     │
│                                                                         │
│   With Jitter (randomization to prevent thundering herd):              │
│                                                                         │
│   delay = min(cap, base * 2^attempt) + random(0, 1000)                 │
│                                                                         │
│   Timeline:                                                             │
│   ─────┬──────┬────────┬────────────────┬─────────────────────────▶   │
│        │      │        │                │                              │
│      Fail   Retry    Retry            Retry                            │
│             +1s      +2s              +4s                              │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Bulkhead Pattern

```
┌────────────────────────────────────────────────────────────────────────┐
│                        BULKHEAD PATTERN                                 │
│                                                                         │
│   Without Bulkhead:                                                     │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                    Shared Thread Pool (100)                      │  │
│   │  Service A, B, C all compete for same resources                 │  │
│   │  If A fails, it can exhaust pool and affect B, C                │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│   With Bulkhead:                                                        │
│   ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐   │
│   │  Service A Pool   │ │  Service B Pool   │ │  Service C Pool   │   │
│   │     (30 threads)  │ │     (40 threads)  │ │     (30 threads)  │   │
│   │                   │ │                   │ │                   │   │
│   │  Isolated from    │ │  Isolated from    │ │  Isolated from    │   │
│   │  other services   │ │  other services   │ │  other services   │   │
│   └───────────────────┘ └───────────────────┘ └───────────────────┘   │
│                                                                         │
│   Types:                                                                │
│   • Thread pool isolation                                              │
│   • Semaphore isolation                                                │
│   • Connection pool isolation                                          │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Timeout Pattern

```
Client ──▶ Service A ──▶ Service B ──▶ Service C

Timeouts should decrease as you go deeper:
  Client timeout:    10s
  Service A timeout:  5s
  Service B timeout:  2s
  
This prevents cascading timeouts and resource exhaustion.
```

### Rate Limiting

**Algorithms:**

| Algorithm | Description | Use Case |
|-----------|-------------|----------|
| Token Bucket | Refills at constant rate | Allows bursts |
| Leaky Bucket | Processes at constant rate | Smooth output |
| Fixed Window | Count per time window | Simple implementation |
| Sliding Window | Rolling time window | More accurate |

---

## Security Patterns

### Zero Trust Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                      ZERO TRUST PRINCIPLES                              │
│                                                                         │
│   "Never trust, always verify"                                         │
│                                                                         │
│   1. Verify explicitly                                                  │
│      • Authenticate and authorize every request                        │
│      • Use all available data points                                   │
│                                                                         │
│   2. Use least privilege access                                        │
│      • Just-in-time access                                             │
│      • Just-enough access                                              │
│      • Risk-based adaptive policies                                    │
│                                                                         │
│   3. Assume breach                                                      │
│      • Minimize blast radius                                           │
│      • Segment access                                                  │
│      • Verify end-to-end encryption                                    │
│      • Use analytics for visibility                                    │
│                                                                         │
│   Implementation:                                                       │
│   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐  │
│   │   Identity  │ │   Device    │ │   Network   │ │   Application   │  │
│   │  Verification│ │   Health   │ │   Security  │ │     Security    │  │
│   │             │ │             │ │   mTLS      │ │    Authorization│  │
│   └─────────────┘ └─────────────┘ └─────────────┘ └─────────────────┘  │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### OAuth 2.0 / OIDC Flows

```
┌────────────────────────────────────────────────────────────────────────┐
│                    AUTHORIZATION CODE FLOW                              │
│                                                                         │
│   User ──▶ Client App ──▶ Authorization Server                        │
│                                  │                                      │
│              ◀── Authorization Code ──                                 │
│                                                                         │
│   Client App ──▶ Token Endpoint (with code + client secret)           │
│                                  │                                      │
│              ◀── Access Token + Refresh Token + ID Token ──            │
│                                                                         │
│   Client App ──▶ Resource Server (with Access Token)                   │
│                                  │                                      │
│              ◀── Protected Resource ──                                 │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Messaging Patterns

### Publisher/Subscriber

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PUB/SUB PATTERN                                  │
│                                                                         │
│   Publishers                Topic/Exchange              Subscribers    │
│                                                                         │
│   ┌───────────┐                                       ┌───────────┐   │
│   │ Service A │ ────┐                           ┌────▶│ Service X │   │
│   └───────────┘     │     ┌───────────────┐    │     └───────────┘   │
│                     ├────▶│   Message     │────┤                      │
│   ┌───────────┐     │     │   Broker      │    │     ┌───────────┐   │
│   │ Service B │ ────┘     │(Kafka/RabbitMQ)│────┼────▶│ Service Y │   │
│   └───────────┘           └───────────────┘    │     └───────────┘   │
│                                                │                      │
│                                                │     ┌───────────┐   │
│                                                └────▶│ Service Z │   │
│                                                      └───────────┘   │
│                                                                         │
│   Benefits: Decoupling, scalability, async processing                  │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Event-Driven Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                    EVENT-DRIVEN ARCHITECTURE                            │
│                                                                         │
│   Event Types:                                                          │
│                                                                         │
│   1. Domain Events (business facts)                                     │
│      • OrderPlaced, PaymentReceived, ItemShipped                       │
│                                                                         │
│   2. Integration Events (cross-service)                                 │
│      • OrderCreatedIntegrationEvent                                    │
│                                                                         │
│   3. Notification Events                                                │
│      • EmailSent, SMSDelivered                                         │
│                                                                         │
│   Delivery Guarantees:                                                  │
│   • At-most-once:  May lose messages (fastest)                         │
│   • At-least-once: May duplicate (safe with idempotency)               │
│   • Exactly-once:  No loss, no duplicates (most complex)               │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Deployment Patterns

### Strangler Fig Pattern

For migrating from monolith to microservices:

```
Phase 1:              Phase 2:              Phase 3:
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│             │      │   Facade    │      │   Facade    │
│  Monolith   │      │     │       │      │     │       │
│             │      │ ┌───┴───┐   │      │     │       │
│  All        │  ──▶ │ │Micro 1│   │  ──▶ │ ┌───┴───┐   │
│  Features   │      │ └───────┘   │      │ │Micro 1│   │
│             │      │             │      │ └───────┘   │
│             │      │   Monolith  │      │ ┌───────┐   │
│             │      │   (Smaller) │      │ │Micro 2│   │
│             │      │             │      │ └───────┘   │
└─────────────┘      └─────────────┘      │ ┌───────┐   │
                                          │ │Micro 3│   │
                                          │ └───────┘   │
                                          └─────────────┘
```

### Sidecar Pattern

```
┌────────────────────────────────────────────────────────────────────────┐
│                          POD                                            │
│                                                                         │
│   ┌─────────────────────┐        ┌─────────────────────┐              │
│   │                     │        │                     │              │
│   │   Main Container    │◀──────▶│  Sidecar Container  │              │
│   │                     │        │                     │              │
│   │   (Application)     │ Shared │  (Helper Service)   │              │
│   │                     │ Volume │                     │              │
│   │                     │   or   │  • Logging agent    │              │
│   │                     │ Network│  • Proxy            │              │
│   │                     │        │  • Config sync      │              │
│   │                     │        │  • Secrets manager  │              │
│   │                     │        │                     │              │
│   └─────────────────────┘        └─────────────────────┘              │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Ambassador Pattern

```
┌────────────────────────────────────────────────────────────────────────┐
│                       AMBASSADOR PATTERN                                │
│                                                                         │
│   ┌──────────────────────────────────────────────────────────────────┐ │
│   │                          POD                                      │ │
│   │                                                                   │ │
│   │   ┌─────────────────┐        ┌─────────────────┐                 │ │
│   │   │                 │        │    Ambassador   │                 │ │
│   │   │    Application  │───────▶│     Sidecar     │────────┐       │ │
│   │   │                 │  Local │                 │        │       │ │
│   │   │  "Connect to    │  Call  │  • Connection   │        │       │ │
│   │   │   localhost"    │        │    pooling      │        │       │ │
│   │   │                 │        │  • Retry logic  │        │       │ │
│   │   └─────────────────┘        │  • TLS          │        │       │ │
│   │                              │  • Auth         │        │       │ │
│   │                              └─────────────────┘        │       │ │
│   │                                                         │       │ │
│   └─────────────────────────────────────────────────────────┼───────┘ │
│                                                              │         │
│                                                              ▼         │
│                                                    ┌────────────────┐ │
│                                                    │ External DB /  │ │
│                                                    │ Legacy System  │ │
│                                                    └────────────────┘ │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```
