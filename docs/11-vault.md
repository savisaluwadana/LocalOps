# HashiCorp Vault Complete Guide

## Table of Contents

1. [Secrets Management Fundamentals](#secrets-management-fundamentals)
2. [What is Vault?](#what-is-vault)
3. [Architecture](#architecture)
4. [Secrets Engines](#secrets-engines)
5. [Authentication Methods](#authentication-methods)
6. [Policies](#policies)
7. [Dynamic Secrets](#dynamic-secrets)
8. [Kubernetes Integration](#kubernetes-integration)
9. [Best Practices](#best-practices)

---

## Secrets Management Fundamentals

### The Problem

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    WHERE SECRETS END UP                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ❌ BAD PRACTICES:                                                      │
│                                                                          │
│   • Hardcoded in source code                                            │
│     password = "super_secret_123"                                       │
│                                                                          │
│   • In environment variables (visible in process list)                  │
│     export DB_PASSWORD=secret123                                        │
│                                                                          │
│   • In config files committed to Git                                    │
│     config.yaml: password: my_password                                  │
│                                                                          │
│   • Shared via Slack/email                                              │
│     "Here's the production password..."                                 │
│                                                                          │
│   • Same password everywhere                                            │
│     dev, staging, prod all use "password123"                            │
│                                                                          │
│   ✓ PROPER SECRETS MANAGEMENT:                                          │
│                                                                          │
│   • Centralized secure storage                                          │
│   • Access control and audit                                            │
│   • Automatic rotation                                                  │
│   • Encryption at rest and in transit                                   │
│   • Dynamic, short-lived credentials                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## What is Vault?

**HashiCorp Vault** is a tool for securely storing and accessing secrets. It provides:

- **Secret Storage** - Encrypted storage for sensitive data
- **Dynamic Secrets** - Generate credentials on-demand
- **Data Encryption** - Encrypt data without storing it
- **Leasing & Renewal** - Time-bound access with automatic revocation
- **Revocation** - Revoke single secrets or entire trees

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        VAULT ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                       HTTP API                                  │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                              │                                           │
│   ┌───────────────┬──────────┴──────────┬───────────────┐               │
│   │               │                     │               │               │
│   ▼               ▼                     ▼               ▼               │
│   ┌───────┐   ┌───────┐           ┌───────┐       ┌───────┐            │
│   │ Auth  │   │Secrets│           │ Audit │       │ System │           │
│   │Methods│   │Engines│           │Devices│       │Backend │           │
│   └───────┘   └───────┘           └───────┘       └───────┘            │
│                              │                                           │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                    BARRIER (Encryption)                         │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                              │                                           │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                    STORAGE BACKEND                              │    │
│   │            (Consul, etcd, S3, PostgreSQL, etc.)                │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Seal/Unseal Process

Vault starts **sealed** - it can't access its own data until unsealed.

```
SEALED STATE    →   UNSEAL (with keys)   →   UNSEALED STATE
Cannot decrypt      Provide key shares       Can access secrets
Cannot read data    Reconstruct master key   API fully operational
```

---

## Secrets Engines

### KV Secrets Engine

Store arbitrary key-value pairs:

```bash
# Write a secret
vault kv put secret/myapp/config \
  database_url="postgresql://..." \
  api_key="sk-..."

# Read a secret
vault kv get secret/myapp/config

# List secrets
vault kv list secret/myapp
```

### Database Secrets Engine

Generate database credentials dynamically:

```bash
# Configure database connection
vault write database/config/my-postgresql-database \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb" \
  allowed_roles="my-role" \
  username="vault-admin" \
  password="admin-password"

# Create a role
vault write database/roles/my-role \
  db_name=my-postgresql-database \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}';" \
  default_ttl="1h" \
  max_ttl="24h"

# Get dynamic credentials
vault read database/creds/my-role
# Returns: username/password valid for 1 hour
```

### AWS Secrets Engine

Generate AWS credentials on-demand:

```bash
# Configure AWS
vault write aws/config/root \
  access_key=AKIAIOSFODNN7EXAMPLE \
  secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Create role
vault write aws/roles/my-role \
  credential_type=iam_user \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF

# Get credentials
vault read aws/creds/my-role
```

---

## Authentication Methods

### Token Auth

Every interaction uses a token internally:

```bash
# Login with root token
vault login hvs.CAESID...

# Create new token
vault token create -ttl=1h -policy=my-policy
```

### Kubernetes Auth

Authenticate using Kubernetes service accounts:

```bash
# Configure Kubernetes auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

vault write auth/kubernetes/role/my-app \
  bound_service_account_names=my-app \
  bound_service_account_namespaces=production \
  policies=my-app-policy \
  ttl=1h
```

### Other Methods

| Method | Use Case |
|--------|----------|
| AppRole | CI/CD and automated systems |
| LDAP/AD | Enterprise directory integration |
| OIDC | SSO integration |
| GitHub | Developer access |

---

## Policies

Policies define what a token can access:

```hcl
# my-app-policy.hcl

# Read secrets for my-app
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

# Generate database credentials
path "database/creds/my-role" {
  capabilities = ["read"]
}

# Deny access to admin secrets
path "secret/data/admin/*" {
  capabilities = ["deny"]
}
```

### Capabilities

| Capability | Description |
|------------|-------------|
| `create` | Create data at path |
| `read` | Read data at path |
| `update` | Update data at path |
| `delete` | Delete data at path |
| `list` | List paths |
| `deny` | Explicit deny |

---

## Dynamic Secrets

### Why Dynamic Secrets?

```
Static Secrets:              Dynamic Secrets:
┌──────────────────┐        ┌──────────────────┐
│ password123      │        │ Generated: xyz... │
│ Shared by all    │        │ TTL: 1 hour       │
│ Never rotates    │        │ Unique per app    │
│ Hard to revoke   │        │ Auto-revokes      │
└──────────────────┘        └──────────────────┘
```

### Benefits

1. **No shared secrets** - Each app gets unique credentials
2. **Automatic expiration** - Credentials are short-lived
3. **Easy revocation** - Revoke a lease, credential is invalid
4. **Audit trail** - Know who requested what credentials
5. **No manual rotation** - Vault handles it automatically

---

## Kubernetes Integration

### Vault Agent Injector

Automatically inject secrets into pods:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "my-app"
        vault.hashicorp.com/agent-inject-secret-config.txt: "secret/data/myapp/config"
    spec:
      serviceAccountName: my-app
      containers:
        - name: my-app
          image: my-app:latest
          # Secret available at /vault/secrets/config.txt
```

### Vault CSI Provider

Mount secrets as volumes:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: my-app
      image: my-app:latest
      volumeMounts:
        - name: secrets
          mountPath: "/etc/secrets"
          readOnly: true
  volumes:
    - name: secrets
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: vault-database
```

---

## Best Practices

### Security

1. **Use dynamic secrets** when possible
2. **Set appropriate TTLs** - Shorter is better
3. **Principle of least privilege** - Minimal policies
4. **Enable audit logging** - Track all access
5. **Use namespaces** - Isolate teams/environments

### Operations

1. **High availability setup** - Multiple Vault nodes
2. **Disaster recovery** - Regular snapshots
3. **Seal Vault during emergencies** - Emergency procedure
4. **Rotate root tokens** - Don't share/store permanently
5. **Monitor token usage** - Alert on anomalies

### Development

1. **Never hardcode Vault tokens** in applications
2. **Use Vault Agent** for token management
3. **Handle secret renewal** - Don't assume static values
4. **Graceful degradation** - What if Vault is unavailable?

This guide covers HashiCorp Vault from fundamentals to advanced integration patterns for secure secrets management.
