# Security Best Practices Guide

Comprehensive security guide for DevOps and cloud-native environments.

## Table of Contents

1. [Security Principles](#security-principles)
2. [Container Security](#container-security)
3. [Kubernetes Security](#kubernetes-security)
4. [CI/CD Security](#cicd-security)
5. [Network Security](#network-security)
6. [Secrets Management](#secrets-management)
7. [Compliance](#compliance)

---

## Security Principles

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DEFENSE IN DEPTH                                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Layer 1: Physical Security                                                         │
│   └── Data center access, hardware security                                          │
│                                                                                      │
│   Layer 2: Network Security                                                          │
│   └── Firewall, WAF, DDoS protection, VPN                                           │
│                                                                                      │
│   Layer 3: Identity & Access                                                         │
│   └── SSO, MFA, RBAC, least privilege                                               │
│                                                                                      │
│   Layer 4: Application Security                                                      │
│   └── Input validation, authentication, authorization                               │
│                                                                                      │
│   Layer 5: Data Security                                                             │
│   └── Encryption at rest and in transit, tokenization                               │
│                                                                                      │
│   Layer 6: Monitoring & Response                                                     │
│   └── SIEM, intrusion detection, incident response                                  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Principle of Least Privilege

**Definition:** Grant only the minimum permissions necessary to perform a task.

**Implementation:**
| Context | Practice |
|---------|----------|
| IAM | Role-based access, time-limited tokens |
| Kubernetes | RBAC, Pod Security Standards |
| Databases | Read-only users for read operations |
| Networks | Default deny, explicit allow |
| Secrets | Just-in-time access |

---

## Container Security

### Image Security

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        CONTAINER IMAGE SECURITY                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   BUILD                                                                              │
│   ├── Use minimal base images (distroless, alpine)                                  │
│   ├── Don't run as root                                                             │
│   ├── Use multi-stage builds                                                        │
│   ├── Pin image versions (no :latest)                                               │
│   └── Remove unnecessary packages                                                   │
│                                                                                      │
│   SCAN                                                                               │
│   ├── Scan for CVEs (Trivy, Grype, Snyk)                                           │
│   ├── Check for secrets in layers                                                   │
│   ├── Verify base image integrity                                                   │
│   └── Check for misconfigurations                                                   │
│                                                                                      │
│   DEPLOY                                                                             │
│   ├── Sign images (Cosign/Sigstore)                                                │
│   ├── Verify signatures at deploy time                                              │
│   ├── Use allowlisted registries only                                               │
│   └── Enforce image policies                                                        │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Dockerfile Best Practices

```dockerfile
# Use specific version, not :latest
FROM python:3.11-slim-bookworm

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Set working directory
WORKDIR /app

# Install dependencies first (cache optimization)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Use exec form for signals
ENTRYPOINT ["python", "-m", "gunicorn"]
CMD ["--bind", "0.0.0.0:8000", "app:app"]
```

### Runtime Security

| Control | Purpose | Tools |
|---------|---------|-------|
| Read-only filesystem | Prevent tampering | securityContext |
| No privilege escalation | Prevent privilege abuse | allowPrivilegeEscalation: false |
| Drop capabilities | Minimize attack surface | drop: ["ALL"] |
| Seccomp profiles | Restrict system calls | RuntimeDefault |
| AppArmor/SELinux | Mandatory access control | Profiles |

---

## Kubernetes Security

### Pod Security

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  
  containers:
    - name: app
      image: myapp:v1
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
      resources:
        limits:
          cpu: 500m
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
```

### Pod Security Standards

| Standard | Description | Use Case |
|----------|-------------|----------|
| **Privileged** | Unrestricted | System-level operations |
| **Baseline** | Minimally restrictive | Most workloads |
| **Restricted** | Heavily restricted | Sensitive workloads |

### RBAC Configuration

```yaml
# Role for read-only access to pods
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]

---
# Bind role to user
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
  - kind: User
    name: developer@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies

```yaml
# Default deny all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress

---
# Allow specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - port: 8080
```

---

## CI/CD Security

### Pipeline Security

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           SECURE CI/CD PIPELINE                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   CODE STAGE                                                                         │
│   ├── Pre-commit hooks (secrets detection, linting)                                 │
│   ├── Branch protection (required reviews)                                          │
│   └── Signed commits                                                                │
│                                                                                      │
│   BUILD STAGE                                                                        │
│   ├── Isolated build environments                                                   │
│   ├── Dependency scanning (SCA)                                                     │
│   ├── Static analysis (SAST)                                                        │
│   ├── SBOM generation                                                               │
│   └── No secrets in build logs                                                      │
│                                                                                      │
│   TEST STAGE                                                                         │
│   ├── Security unit tests                                                           │
│   ├── Integration testing                                                           │
│   ├── DAST (dynamic scanning)                                                       │
│   └── Container scanning                                                            │
│                                                                                      │
│   DEPLOY STAGE                                                                       │
│   ├── Signed artifacts                                                              │
│   ├── Environment-specific secrets                                                  │
│   ├── Approval gates for production                                                 │
│   └── Deployment verification                                                       │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Security Scanning Types

| Type | What it Scans | When | Tools |
|------|---------------|------|-------|
| SAST | Source code | Build | SonarQube, Semgrep, CodeQL |
| SCA | Dependencies | Build | Snyk, Dependabot, OWASP Dependency-Check |
| DAST | Running app | Test | OWASP ZAP, Burp Suite |
| Container | Images | Build/Deploy | Trivy, Grype, Clair |
| IaC | Terraform/K8s | Build | Checkov, tfsec, Kubesec |
| Secrets | Code/Configs | Pre-commit | GitLeaks, TruffleHog |

---

## Network Security

### Zero Trust Networking

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        ZERO TRUST NETWORK ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Traditional (Castle & Moat):                                                       │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                    TRUSTED NETWORK                                           │   │
│   │   ──────────────────────────────────────────────────                        │   │
│   │   All internal traffic trusted                                              │   │
│   │   ──────────────────────────────────────────────────                        │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   Zero Trust:                                                                        │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   NEVER TRUST, ALWAYS VERIFY                                                │   │
│   │                                                                              │   │
│   │   ┌───────┐    Authenticate    ┌───────┐   Authorize    ┌───────┐          │   │
│   │   │Service│───────────────────▶│ Policy│───────────────▶│Service│          │   │
│   │   │   A   │       mTLS         │ Engine│   RBAC/ABAC    │   B   │          │   │
│   │   └───────┘                    └───────┘                └───────┘          │   │
│   │                                                                              │   │
│   │   Every request is authenticated, authorized, and encrypted                 │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### TLS/mTLS

**mTLS (Mutual TLS):**
1. Client presents certificate to server
2. Server validates client certificate
3. Server presents certificate to client
4. Client validates server certificate
5. Encrypted session established

---

## Secrets Management

### Secret Types and Storage

| Secret Type | Storage | Rotation | Access |
|-------------|---------|----------|--------|
| API Keys | Vault | 30 days | Just-in-time |
| DB Passwords | Vault | 24h (dynamic) | Dynamic generation |
| TLS Certs | Cert-Manager | 90 days | Auto-renewal |
| SSH Keys | Vault | 7 days | Signed keys |
| Tokens | Vault | 1h | Dynamic |

### Anti-Patterns

❌ **Don't:**
- Store secrets in code or config files
- Pass secrets as command-line arguments
- Log secrets anywhere
- Share secrets via chat/email
- Use the same secret across environments

✅ **Do:**
- Use secrets management (Vault, AWS Secrets Manager)
- Inject secrets at runtime
- Encrypt secrets at rest
- Audit secret access
- Rotate secrets regularly

---

## Compliance

### Compliance Frameworks

| Framework | Focus | Industry |
|-----------|-------|----------|
| SOC 2 | Security controls | Technology |
| HIPAA | Health data | Healthcare |
| PCI-DSS | Payment data | Finance/Retail |
| GDPR | Data privacy | EU operations |
| ISO 27001 | Information security | Any |
| FedRAMP | Government | US Government |

### Compliance Automation

```yaml
# Example compliance check configuration
compliance:
  frameworks:
    - soc2
    - hipaa
  
  controls:
    encryption_at_rest:
      enabled: true
      check: "all-storage-encrypted"
      
    audit_logging:
      enabled: true
      retention_days: 365
      
    access_control:
      mfa_required: true
      session_timeout: 15m
      
    encryption_in_transit:
      tls_version: "1.2+"
      mtls_services: true
```

### Audit Logging Requirements

| What to Log | Why |
|-------------|-----|
| Authentication events | Who accessed what |
| Authorization decisions | Access granted/denied |
| Data access | Who read/modified data |
| Configuration changes | What changed and when |
| API requests | Security investigations |
| Administrative actions | Privileged access audit |
