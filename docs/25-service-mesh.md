# Service Mesh Guide

## Table of Contents

1. [What is a Service Mesh?](#what-is-a-service-mesh)
2. [Architecture](#architecture)
3. [Core Features](#core-features)
4. [Istio Deep Dive](#istio-deep-dive)
5. [Linkerd Deep Dive](#linkerd-deep-dive)
6. [Service Mesh Interface (SMI)](#service-mesh-interface-smi)

---

## What is a Service Mesh?

A **service mesh** is a dedicated infrastructure layer for facilitating service-to-service communications between services or microservices, using a proxy.

It addresses challenges in:
- **Resilience** (Retries, Timeouts)
- **Security** (mTLS, Policy)
- **Observability** (Tracing, Metrics)
- **Traffic Control** (Canary, Blue/Green)

Moving these concerns **out of the application code** and into the **infrastructure**.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SERVICE MESH ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                      Control Plane                              │    │
│   │                                                                │    │
│   │   • Configuration Management (Convert Rules to Proxy Config)   │    │
│   │   • Certificate Authority (Issue Certs for mTLS)               │    │
│   │   • Service Discovery                                          │    │
│   │                                                                │    │
│   └──────────────────────────────┬─────────────────────────────────┘    │
│                                  │ Pushes Config                         │
│                                  ▼                                       │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                        Data Plane                               │    │
│   │                                                                │    │
│   │  ┌──────────────┐                  ┌──────────────┐            │    │
│   │  │ Service A    │                  │ Service B    │            │    │
│   │  │              │                  │              │            │    │
│   │  │ ┌─────────┐  │      mTLS        │ ┌─────────┐  │            │    │
│   │  │ │ Proxy   │◀─┼──────────────────┼▶│ Proxy   │  │            │    │
│   │  │ └─────────┘  │      HTTP/2      │ └─────────┘  │            │    │
│   │  └──────────────┘      gRPC        └──────────────┘            │    │
│   │                                                                │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Sidecar Pattern**: A lightweight proxy (Envoy, Linkerd-proxy) runs alongside every application container in the same Pod. It intercepts all network traffic.

---

## Core Features

### 1. Traffic Management
- **Circuit Breaking**: Stop calling failing services.
- **Retries & Timeouts**: Automatic resilience.
- **Canary Rollouts**: Send 1% traffic to v2.
- **A/B Testing**: Route based on headers.
- **Fault Injection**: Simulate delays or failures to test resilience.

### 2. Security
- **mTLS (Mutual TLS)**: Encrypts traffic between services automatically.
- **Authentication**: Prove identity (SPIFFE).
- **Authorization**: Allow Service A to call Service B but not Service C.

### 3. Observability
- **Golden Signals**: Request rate, error rate, latency.
- **Distributed Tracing**: Span correlation across microservices.
- **Service Graph**: Visualizing dependencies.

---

## Istio Deep Dive

**Istio** is the most popular, feature-rich service mesh.

### Components

- **Istiod**: Monolithic control plane binary.
  - **Pilot**: Service discovery, traffic config (xDS API).
  - **Citadel**: Certificate management.
  - **Galley**: Validation.
- **Envoy**: The data plane proxy.

### VirtualService & DestinationRule

```yaml
# VirtualService: Routing logic (How do I get there?)
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 75
    - destination:
        host: reviews
        subset: v2
      weight: 25

# DestinationRule: Policies after routing (What happens when I arrive?)
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

---

## Linkerd Deep Dive

**Linkerd** focuses on simplicity, lightness, and performance. It uses a Rust-based micro-proxy (not Envoy).

### Philosophy
- No configuration by default ("It just works").
- Ultra-lightweight.
- Kubernetes-native only.

### Architecture
- **Control Plane**: Identity, Destination, Proxy Injector.
- **Data Plane**: Linkerd-proxy (Rust).

### Key Differentiator
Istio tries to do everything (VMs, complex routing). Linkerd tries to do the most important things (mTLS, golden metrics, simple reliability) with near-zero overhead.

---

## Service Mesh Interface (SMI)

Standard interface for service meshes on Kubernetes.

- **Traffic Split**: Percentage-based traffic shifting.
- **Traffic Access Control**: Authorization.
- **Traffic Specs**: Define per-protocol routes.
- **Traffic Metrics**: Unified metric standard.
