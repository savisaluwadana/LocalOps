# Security in DevOps Complete Guide

## Table of Contents

1. [DevSecOps Fundamentals](#devsecops-fundamentals)
2. [Shift Left Security](#shift-left-security)
3. [Container Security](#container-security)
4. [Kubernetes Security](#kubernetes-security)
5. [CI/CD Security](#cicd-security)
6. [Infrastructure Security](#infrastructure-security)
7. [Secrets Management](#secrets-management)
8. [Compliance and Auditing](#compliance-and-auditing)
9. [Incident Response](#incident-response)

---

## DevSecOps Fundamentals

### What is DevSecOps?

**DevSecOps** integrates security practices into every phase of the software development lifecycle, making security everyone's responsibility.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     TRADITIONAL vs DEVSECOPS                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   TRADITIONAL:                                                           │
│   ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐ ┌────────┐             │
│   │  Dev   │→│ Build  │→│  Test  │→│ Security │→│ Deploy │             │
│   └────────┘ └────────┘ └────────┘ └──────────┘ └────────┘             │
│                                          ↑                               │
│                                    Late, expensive                       │
│                                    to fix issues                         │
│                                                                          │
│   DEVSECOPS:                                                             │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │                    CONTINUOUS SECURITY                        │      │
│   │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                │      │
│   │  │  Dev   │→│ Build  │→│  Test  │→│ Deploy │                │      │
│   │  │+SAST   │ │+SCA    │ │+DAST   │ │+Runtime│                │      │
│   │  └────────┘ └────────┘ └────────┘ └────────┘                │      │
│   └──────────────────────────────────────────────────────────────┘      │
│                           ↑                                              │
│                    Early, cheap                                         │
│                    to fix issues                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Shift Left Security

### Security Testing Types

| Test Type | When | What It Checks |
|-----------|------|----------------|
| **SAST** | At commit | Source code vulnerabilities |
| **SCA** | At build | Dependency vulnerabilities |
| **DAST** | At staging | Running application vulnerabilities |
| **IAST** | At test | Runtime code analysis |

### Pipeline Integration

```yaml
# GitHub Actions example
security-scan:
  runs-on: ubuntu-latest
  steps:
    # SAST - Static Analysis
    - name: Run Semgrep
      uses: returntocorp/semgrep-action@v1
    
    # SCA - Dependency Check
    - name: Run Snyk
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    
    # Container Scanning
    - name: Run Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'myapp:latest'
        severity: 'CRITICAL,HIGH'
```

---

## Container Security

### Image Security

```dockerfile
# SECURE DOCKERFILE

# 1. Use specific, minimal base image
FROM node:20-alpine AS base

# 2. Don't run as root
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

# 3. Multi-stage build (minimal final image)
FROM base AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM base AS runtime
WORKDIR /app
# 4. Copy only what's needed
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=appuser:appgroup . .

# 5. Run as non-root
USER appuser

# 6. Read-only filesystem compatible
CMD ["node", "server.js"]
```

### Image Scanning

```bash
# Scan with Trivy
trivy image myapp:latest

# Scan with Grype
grype myapp:latest

# Scan in CI (fail on CRITICAL)
trivy image --exit-code 1 --severity CRITICAL myapp:latest
```

### Registry Security

| Control | Description |
|---------|-------------|
| Private registry | Don't pull from public Docker Hub |
| Image signing | Cosign, Notary |
| Admission control | Only allow signed images |
| Vulnerability scanning | Scan on push |

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
    fsGroup: 1000
  containers:
    - name: app
      image: myapp:latest
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
      resources:
        limits:
          memory: "128Mi"
          cpu: "500m"
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}  # All pods
  policyTypes:
    - Ingress
    - Egress
  # No ingress/egress rules = deny all
---
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

### RBAC

```yaml
# Least privilege role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    resourceNames: ["app-config"]  # Specific resource
    verbs: ["get"]                  # Read only
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
subjects:
  - kind: ServiceAccount
    name: app-service-account
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

---

## CI/CD Security

### Pipeline Security

| Risk | Mitigation |
|------|------------|
| Compromised dependencies | Lock versions, scan before use |
| Leaked secrets | Use secret managers, never in code |
| Malicious PRs | Require approval, limit permissions |
| Compromised runners | Ephemeral runners, least privilege |

### Secret Handling

```yaml
# DON'T: Secrets in environment
env:
  DB_PASSWORD: supersecret123  # ❌

# DO: Use secret references
env:
  DB_PASSWORD:
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password  # ✓
```

### Supply Chain Security

```yaml
# Sign and verify images
cosign sign myregistry/myapp:latest
cosign verify myregistry/myapp:latest

# SBOM generation
syft myapp:latest -o spdx-json > sbom.json

# Verify SBOM
grype sbom:./sbom.json
```

---

## Infrastructure Security

### Network Security

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    NETWORK SECURITY LAYERS                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   INTERNET                                                               │
│       │                                                                  │
│       ▼                                                                  │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │ WAF (Web Application Firewall)                                  │    │
│   │ • SQL injection protection                                      │    │
│   │ • XSS protection                                                │    │
│   │ • Rate limiting                                                 │    │
│   └────────────────────────────────────────────────────────────────┘    │
│       │                                                                  │
│       ▼                                                                  │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │ Load Balancer / Ingress                                         │    │
│   │ • TLS termination                                               │    │
│   │ • DDoS protection                                               │    │
│   └────────────────────────────────────────────────────────────────┘    │
│       │                                                                  │
│       ▼                                                                  │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │ Network Policies / Security Groups                              │    │
│   │ • Pod-to-pod restrictions                                       │    │
│   │ • Namespace isolation                                           │    │
│   └────────────────────────────────────────────────────────────────┘    │
│       │                                                                  │
│       ▼                                                                  │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │ Service Mesh (mTLS)                                             │    │
│   │ • Encrypted service-to-service                                  │    │
│   │ • Identity verification                                         │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Secrets Management

### Hierarchy of Options

| Option | Security Level | Use Case |
|--------|---------------|----------|
| Hardcoded | ❌ Terrible | Never |
| Environment vars | ⚠️ Poor | Development only |
| Kubernetes Secrets | ⚠️ Basic | Simple deployments |
| Sealed Secrets | ✓ Good | GitOps workflows |
| External Secrets | ✓✓ Better | Cloud integration |
| HashiCorp Vault | ✓✓✓ Best | Enterprise |

### Sealed Secrets

```yaml
# Encrypt secret for GitOps
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: my-secret
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiT...  # Encrypted
```

---

## Compliance and Auditing

### Audit Logging

```yaml
# Kubernetes audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log all requests to secrets
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets"]
  
  # Log all changes
  - level: RequestResponse
    verbs: ["create", "update", "patch", "delete"]
```

### Compliance Frameworks

| Framework | Focus |
|-----------|-------|
| SOC 2 | Security controls |
| PCI DSS | Payment data |
| HIPAA | Health data |
| GDPR | EU privacy |
| ISO 27001 | Information security |

---

## Incident Response

### Response Steps

1. **Detect** - Monitoring and alerting
2. **Contain** - Limit damage
3. **Eradicate** - Remove threat
4. **Recover** - Restore service
5. **Learn** - Post-mortem

### Runbook Example

```markdown
# Security Incident: Compromised Container

## Detection
- Alert: Unusual outbound network traffic
- Source: Container in production namespace

## Immediate Actions
1. [ ] Scale deployment to 0: `kubectl scale deploy/app --replicas=0`
2. [ ] Capture logs: `kubectl logs -l app=compromised > incident.log`
3. [ ] Notify security team

## Investigation
1. [ ] Review audit logs
2. [ ] Check for lateral movement
3. [ ] Identify entry point

## Recovery
1. [ ] Rebuild image from clean source
2. [ ] Rotate all secrets
3. [ ] Deploy new version
4. [ ] Monitor closely
```

This guide covers security fundamentals for DevOps with practical examples for securing the entire software delivery pipeline.
