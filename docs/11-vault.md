# Secret Management with Vault

## Why Vault?

**HashiCorp Vault** securely stores and manages secrets, encryption keys, and certificates. It solves:

- Secrets sprawl (passwords in code, env vars, config files)
- No audit trail of secret access
- Manual secret rotation
- Encryption key management

---

## Core Concepts

### Secret Engines

| Engine | Purpose |
|--------|---------|
| **KV** | Key-value store for arbitrary secrets |
| **Database** | Dynamic database credentials |
| **AWS/GCP** | Cloud provider credentials |
| **PKI** | TLS certificates |
| **Transit** | Encryption as a service |

### Authentication Methods

| Method | Use Case |
|--------|----------|
| **Token** | Direct API access |
| **AppRole** | Machine/application auth |
| **Kubernetes** | K8s service accounts |
| **LDAP/OIDC** | User authentication |

---

## Hands-On: Deploy Vault

### Docker Setup

Create `playground/vault/docker-compose.yml`:

```yaml
version: '3.8'

services:
  vault:
    image: hashicorp/vault:latest
    container_name: vault
    ports:
      - "8200:8200"
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: root
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
    cap_add:
      - IPC_LOCK
    restart: unless-stopped

volumes:
  vault_data:
```

```bash
cd playground/vault
docker compose up -d

# Access UI: http://localhost:8200
# Token: root
```

### CLI Setup

```bash
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# Check status
vault status
```

---

## Basic Operations

### Store Secrets

```bash
# Enable KV secrets engine (v2)
vault secrets enable -path=secret kv-v2

# Write a secret
vault kv put secret/myapp/config \
    username="admin" \
    password="supersecret123" \
    api_key="abc123xyz"

# Read a secret
vault kv get secret/myapp/config

# Get specific field
vault kv get -field=password secret/myapp/config

# List secrets
vault kv list secret/myapp
```

### Dynamic Database Credentials

```bash
# Enable database engine
vault secrets enable database

# Configure MySQL connection
vault write database/config/mysql \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(mysql:3306)/" \
    allowed_roles="readonly" \
    username="root" \
    password="rootpassword"

# Create role for read-only access
vault write database/roles/readonly \
    db_name=mysql \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"

# Get dynamic credentials
vault read database/creds/readonly
```

---

## Integration Examples

### In Shell Scripts

```bash
#!/bin/bash
export VAULT_ADDR='http://vault:8200'
export VAULT_TOKEN='...'

DB_PASSWORD=$(vault kv get -field=password secret/myapp/database)
mysql -u admin -p"$DB_PASSWORD" mydb
```

### In Kubernetes

```yaml
# Using Vault Agent Injector
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"
```

### In Terraform

```hcl
provider "vault" {
  address = "http://vault:8200"
}

data "vault_kv_secret_v2" "myapp" {
  mount = "secret"
  name  = "myapp/config"
}

resource "docker_container" "app" {
  env = [
    "DB_PASSWORD=${data.vault_kv_secret_v2.myapp.data["password"]}"
  ]
}
```

---

## Policies (RBAC)

```hcl
# myapp-policy.hcl
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "database/creds/myapp-readonly" {
  capabilities = ["read"]
}
```

```bash
vault policy write myapp myapp-policy.hcl
```
