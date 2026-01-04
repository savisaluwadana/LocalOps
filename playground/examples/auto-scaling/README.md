# Auto-Scaling Example

Horizontal Pod Autoscaler (HPA) for Kubernetes.

## How It Works

```
                     CPU > 70%
                        │
┌───────────────────────┼───────────────────────┐
│                       ▼                       │
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐           HPA  │
│   │Pod1│ │Pod2│ │Pod3│ │Pod4│ ←── Scale Up  │
│   └────┘ └────┘ └────┘ └────┘               │
│                                              │
│              Deployment                      │
└──────────────────────────────────────────────┘
```

## Quick Start

```bash
# Apply manifests
kubectl apply -f manifests/

# Watch scaling
kubectl get hpa -w

# Generate load
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- \
    /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

## Kubernetes HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```
