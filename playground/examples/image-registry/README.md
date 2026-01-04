# Image Registry Platform

Private container registry with vulnerability scanning, image signing, and replication.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          IMAGE REGISTRY PLATFORM                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         HARBOR REGISTRY                                        │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Core Service  │  │   Notary        │  │       Trivy Scanner             ││  │
│  │  │   (Registry)    │  │   (Signing)     │  │       (Vulnerability)           ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  │                                                                                │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Job Service   │  │   Portal        │  │       Chartmuseum               ││  │
│  │  │   (Replication) │  │   (Web UI)      │  │       (Helm Charts)             ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         STORAGE                                                │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    S3 / MinIO / Azure Blob                               │  │  │
│  │  │                    (Image Layers + Manifests)                            │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         REPLICATION                                            │  │
│  │                                                                                │  │
│  │   Primary Registry ◄──────────────────────────▶ DR Registry                   │  │
│  │   (us-east-1)                Pull/Push          (us-west-2)                   │  │
│  │                                                                                │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Private Registry** - Host container images securely
- **Vulnerability Scanning** - Trivy/Clair integration
- **Image Signing** - Notary/Cosign for trusted images
- **Replication** - Cross-region and cross-registry sync
- **RBAC** - Fine-grained access control
- **Helm Charts** - Host Helm chart repository
- **OCI Artifacts** - Store any OCI-compliant artifacts

## Quick Start

```bash
# Install Harbor
helm install harbor harbor/harbor \
  --set expose.type=loadBalancer \
  --set persistence.persistentVolumeClaim.registry.size=100Gi \
  --set trivy.enabled=true

# Login to registry
docker login harbor.example.com

# Push an image
docker tag myapp:v1 harbor.example.com/myproject/myapp:v1
docker push harbor.example.com/myproject/myapp:v1
```

## Access Policies

| Role | Permissions |
|------|-------------|
| Guest | Pull public images |
| Developer | Push/pull project images |
| Project Admin | Manage project members, policies |
| System Admin | Full system access |

## Scanning Policies

```yaml
# Vulnerability threshold
scan_policy:
  scanner: trivy
  auto_scan: true
  prevent_vulnerable: true
  severity_threshold: HIGH
  
# Scan schedule
scan_schedule: "0 0 * * *"  # Daily at midnight
```

## Replication Rules

```yaml
replication:
  - name: dr-replication
    trigger: event_based  # Push triggers sync
    destination: dr.harbor.example.com
    filters:
      - type: name
        pattern: "production/**"
      - type: tag
        pattern: "v*"
    override: true
```

## Retention Policies

| Image Type | Retention |
|------------|-----------|
| Production tags | 90 days |
| Staging tags | 30 days |
| Development | 7 days |
| Untagged | 3 days |
