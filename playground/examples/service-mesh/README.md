# Service Mesh Platform

Production-ready service mesh implementation using Istio with traffic management, security, and observability.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            ISTIO SERVICE MESH                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         CONTROL PLANE                                          │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │     istiod      │  │    Kiali        │  │          Jaeger                 ││  │
│  │  │                 │  │   (Dashboard)   │  │       (Tracing)                 ││  │
│  │  │  • Pilot        │  │                 │  │                                 ││  │
│  │  │  • Citadel      │  └─────────────────┘  └─────────────────────────────────┘│  │
│  │  │  • Galley       │                                                          │  │
│  │  └─────────────────┘                                                          │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DATA PLANE (Envoy Proxies)                             │  │
│  │                                                                                │  │
│  │   ┌─────────────────────┐              ┌─────────────────────┐                │  │
│  │   │        Pod A        │              │        Pod B        │                │  │
│  │   │  ┌───────────────┐  │   mTLS       │  ┌───────────────┐  │                │  │
│  │   │  │  Application  │  │   ◄────────▶ │  │  Application  │  │                │  │
│  │   │  └───────┬───────┘  │              │  └───────┬───────┘  │                │  │
│  │   │          │          │              │          │          │                │  │
│  │   │  ┌───────▼───────┐  │              │  ┌───────▼───────┐  │                │  │
│  │   │  │ Envoy Sidecar │◄─┼──────────────┼─▶│ Envoy Sidecar │  │                │  │
│  │   │  └───────────────┘  │              │  └───────────────┘  │                │  │
│  │   └─────────────────────┘              └─────────────────────┘                │  │
│  │                                                                                │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Traffic Management** - Routing, load balancing, fault injection
- **Security** - mTLS, RBAC, JWT validation
- **Observability** - Metrics, tracing, access logs
- **Policy Enforcement** - Rate limiting, quotas
- **Multi-cluster** - Cross-cluster service discovery

## Quick Start

```bash
# Install Istio
istioctl install --set profile=production

# Enable injection
kubectl label namespace default istio-injection=enabled

# Deploy Kiali dashboard
kubectl apply -f addons/kiali.yaml
```

## Traffic Management

### VirtualService

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews-route
spec:
  hosts:
    - reviews
  http:
    - match:
        - headers:
            end-user:
              exact: jason
      route:
        - destination:
            host: reviews
            subset: v2
    - route:
        - destination:
            host: reviews
            subset: v1
          weight: 90
        - destination:
            host: reviews
            subset: v2
          weight: 10
```

### DestinationRule

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews-destination
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        h2UpgradePolicy: UPGRADE
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
```

## Security Policies

| Policy | Purpose |
|--------|---------|
| PeerAuthentication | mTLS configuration |
| AuthorizationPolicy | RBAC for services |
| RequestAuthentication | JWT validation |

## Observability

Access via Kiali, Grafana, and Jaeger dashboards included in the addons.
