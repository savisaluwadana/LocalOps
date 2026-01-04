# Network & Security

This guide covers networking concepts and security best practices for your DevOps environment.

---

## Docker Networking

### Network Types

| Type | Use Case |
|------|----------|
| **bridge** | Default, containers on same host |
| **host** | Container uses host's network |
| **overlay** | Multi-host networking (Swarm) |
| **none** | No networking |

### Commands

```bash
# Create network
docker network create mynetwork

# Run container on network
docker run -d --network mynetwork --name app nginx

# Connect existing container
docker network connect mynetwork existing-container

# Inspect network
docker network inspect mynetwork
```

---

## Kubernetes Network Policies

Restrict traffic between pods:

```yaml
# playground/kubernetes/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
```

---

## SSL/TLS Certificates

### Generate Self-Signed Cert

```bash
# Create private key
openssl genrsa -out server.key 2048

# Create CSR
openssl req -new -key server.key -out server.csr \
  -subj "/CN=localhost/O=LocalOps"

# Create certificate
openssl x509 -req -days 365 -in server.csr \
  -signkey server.key -out server.crt
```

### Using cert-manager in K8s

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

---

## Security Scanning

### Container Scanning

```bash
# Using Docker Scout
docker scout cves myimage:latest

# Using Trivy
brew install trivy
trivy image myimage:latest
```

### Infrastructure Scanning

```bash
# Using tfsec for Terraform
brew install tfsec
tfsec playground/terraform/

# Using checkov
pip install checkov
checkov -d playground/terraform/
```

---

## Firewall Rules (UFW on Linux VM)

```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow from specific IP
sudo ufw allow from 192.168.1.100

# Check status
sudo ufw status verbose
```
