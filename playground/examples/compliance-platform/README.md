# Compliance Automation Platform

Automated compliance for SOC 2, HIPAA, PCI-DSS, and GDPR with continuous monitoring and evidence collection.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      COMPLIANCE AUTOMATION PLATFORM                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         CONTROL FRAMEWORKS                                     │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐│  │
│  │  │   SOC 2     │  │   HIPAA     │  │   PCI-DSS   │  │       GDPR            ││  │
│  │  │   Type II   │  │   Security  │  │   v4.0      │  │   Privacy             ││  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         CONTINUOUS MONITORING                                  │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   AWS Config    │  │  Azure Policy   │  │    Kubernetes Policies          ││  │
│  │  │   Rules         │  │  Compliance     │  │    (OPA/Kyverno)                ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         EVIDENCE COLLECTION                                    │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Audit Logs    │  │   Config Snapshots│ │    Access Reviews              ││  │
│  │  │   (CloudTrail)  │  │   (Terraform)    │  │    (Okta/Azure AD)             ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         REPORTING & DASHBOARD                                  │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │  Compliance     │  │  Gap Analysis   │  │    Auditor Portal               ││  │
│  │  │  Dashboard      │  │  Reports        │  │    (Evidence Export)            ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-framework** - SOC 2, HIPAA, PCI-DSS, GDPR, ISO 27001
- **Continuous Monitoring** - Real-time compliance status
- **Automated Evidence** - Auto-collect audit artifacts
- **Policy as Code** - OPA/Rego for custom policies
- **Gap Analysis** - Identify compliance gaps
- **Audit Portal** - Self-service for auditors
- **Remediation** - Automated fix suggestions

## Quick Start

```bash
# Deploy compliance controller
kubectl apply -k kubernetes/compliance/

# Run initial assessment
./scripts/run-assessment.sh --framework soc2

# Generate report
./scripts/generate-report.sh --format pdf
```

## Control Mappings

| Control | SOC 2 | PCI-DSS | HIPAA |
|---------|-------|---------|-------|
| Encryption at rest | CC6.1 | 3.4 | 164.312(a) |
| Access control | CC6.3 | 7.1 | 164.312(d) |
| Audit logging | CC7.2 | 10.2 | 164.312(b) |
| Incident response | CC7.4 | 12.10 | 164.308(a) |

## Compliance Status

```yaml
soc2:
  type2:
    status: compliant
    last_audit: 2024-06-15
    controls:
      total: 89
      passing: 87
      failing: 2
      
hipaa:
  status: compliant
  last_assessment: 2024-07-01
  
pci_dss:
  level: 1
  status: in_progress
  due_date: 2024-09-01
```

## Evidence Types

| Type | Frequency | Retention |
|------|-----------|-----------|
| Access logs | Real-time | 1 year |
| Config snapshots | Daily | 3 years |
| Access reviews | Quarterly | 5 years |
| Pen test reports | Annual | 5 years |
| Training records | On completion | 7 years |
