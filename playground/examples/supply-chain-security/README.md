# Supply Chain Security Platform

Comprehensive software supply chain security with SBOM generation, artifact signing, policy enforcement, and vulnerability scanning.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      SUPPLY CHAIN SECURITY PLATFORM                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         BUILD PHASE                                            │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │    Sigstore     │  │     Syft        │  │       Grype                     ││  │
│  │  │   (Signing)     │  │    (SBOM)       │  │   (Vulnerability Scan)          ││  │
│  │  │   Cosign        │  │   CycloneDX     │  │                                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         ATTESTATION & PROVENANCE                               │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │    SLSA         │  │     in-toto     │  │       Rekor                     ││  │
│  │  │  (Provenance)   │  │  (Attestations) │  │  (Transparency Log)             ││  │
│  │  │   Level 3       │  │                 │  │                                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         POLICY ENFORCEMENT                                     │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │    Kyverno      │  │  OPA Gatekeeper │  │       Ratify                    ││  │
│  │  │ (K8s Policies)  │  │  (Admission)    │  │  (Signature Verify)             ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **SBOM Generation** - CycloneDX/SPDX with Syft
- **Artifact Signing** - Sigstore Cosign with keyless signing
- **Signature Verification** - Admission controller enforcement
- **SLSA Provenance** - Build attestations (Level 3)
- **Vulnerability Scanning** - Grype, Trivy integration
- **Transparency Log** - Rekor for immutable records
- **Policy Enforcement** - Block unsigned/vulnerable images

## Quick Start

```bash
# Install Sigstore components
kubectl apply -k kubernetes/sigstore/

# Deploy verification policy
kubectl apply -f policies/require-signatures.yaml

# Sign an image
cosign sign --key cosign.key gcr.io/project/app:v1

# Verify signature
cosign verify --key cosign.pub gcr.io/project/app:v1
```

## SLSA Levels

| Level | Requirements |
|-------|-------------|
| 1 | Build process documented |
| 2 | Hosted build service, signed provenance |
| 3 | Hardened build platform, unforgeable provenance |
| 4 | Two-party review, hermetic builds |

## Pipeline Integration

```yaml
# GitHub Actions Example
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    artifact-name: sbom.spdx.json
    
- name: Sign Image
  run: |
    cosign sign --yes \
      --oidc-issuer=https://token.actions.githubusercontent.com \
      ${{ env.IMAGE }}

- name: Attest SBOM
  run: |
    cosign attest --yes \
      --predicate sbom.spdx.json \
      --type spdx \
      ${{ env.IMAGE }}
```

## Policies

| Policy | Action | Scope |
|--------|--------|-------|
| Require signature | Block | All namespaces |
| No critical CVEs | Block | Production |
| Valid SBOM | Warn | All |
| SLSA Level 2+ | Block | Production |
