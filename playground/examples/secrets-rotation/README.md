# Secrets Rotation Platform

Automated secrets rotation for databases, API keys, and certificates using HashiCorp Vault.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         SECRETS ROTATION PLATFORM                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         HASHICORP VAULT                                        │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Dynamic       │  │   Static        │  │       PKI                       ││  │
│  │  │   Secrets       │  │   Secrets       │  │   (Certificates)                ││  │
│  │  │                 │  │                 │  │                                 ││  │
│  │  │  • Database     │  │  • API Keys     │  │  • TLS Certs                    ││  │
│  │  │  • Cloud IAM    │  │  • Passwords    │  │  • mTLS                         ││  │
│  │  │  • SSH          │  │                 │  │  • Code Signing                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                         ROTATION ENGINES                                       │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Database      │  │   AWS/GCP       │  │       Kubernetes                ││  │
│  │  │   Rotation      │  │   Rotation      │  │       Secrets Sync              ││  │
│  │  │                 │  │                 │  │                                 ││  │
│  │  │  PostgreSQL     │  │  IAM Keys       │  │  External Secrets              ││  │
│  │  │  MySQL          │  │  Service Accts  │  │  Operator                       ││  │
│  │  │  MongoDB        │  │                 │  │                                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         CONSUMERS                                              │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Applications  │  │   CI/CD         │  │       Kubernetes Pods           ││  │
│  │  │   (SDK/API)     │  │   Pipelines     │  │       (Sidecar/CSI)             ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Dynamic Secrets** - Generate credentials on-demand
- **Automatic Rotation** - Scheduled rotation without downtime
- **Lease Management** - TTL-based credential lifecycle
- **Audit Logging** - Complete access audit trail
- **Kubernetes Integration** - External Secrets Operator, CSI driver

## Quick Start

```bash
# Deploy Vault
helm install vault hashicorp/vault --values vault-values.yaml

# Initialize and unseal
kubectl exec -it vault-0 -- vault operator init
kubectl exec -it vault-0 -- vault operator unseal

# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/app" \
    allowed_roles="app-role" \
    username="vault" \
    password="vault-password"
```

## Rotation Schedules

| Secret Type | Rotation Period | Method |
|-------------|-----------------|--------|
| Database credentials | 24 hours | Dynamic generation |
| API keys | 30 days | Scheduled rotation |
| TLS certificates | 90 days | Auto-renewal |
| Service account keys | 7 days | Rotation + revocation |

## Dynamic Database Credentials

```hcl
# Create a role for the application
vault write database/roles/app-role \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# Application gets credentials
vault read database/creds/app-role
# Returns: username: v-app-role-xxxx, password: A1b2C3...
```

## Kubernetes Integration

```yaml
# ExternalSecret syncs Vault secrets to K8s
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: database/creds/app-role
        property: username
    - secretKey: password
      remoteRef:
        key: database/creds/app-role
        property: password
```

## Zero-Downtime Rotation

```
1. Generate new credentials (v2)
2. Distribute v2 to applications
3. Applications start using v2
4. Revoke old credentials (v1)

Timeline:
├── T0: New creds created
├── T1: Apps receive new creds (async)
├── T2: Grace period (both valid)
└── T3: Old creds revoked
```
