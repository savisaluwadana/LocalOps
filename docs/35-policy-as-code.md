# Policy as Code (Governance)

## Table of Contents
1.  [Why Policy as Code?](#why-policy-as-code)
2.  [The Open Policy Agent (OPA)](#the-open-policy-agent-opa)
3.  [Rego Language Basics](#rego-language-basics)
4.  [Kyverno (Kubernetes Native)](#kyverno-kubernetes-native)
5.  [Shift-Left Security](#shift-left-security)

---

## Why Policy as Code?

Traditional security relies on gatekeepers (Security Team) manually reviewing Excel spreadsheets or clicking buttons. This doesn't scale.

**Policy as Code (PaC)** means:
1.  **Version Controlled**: Policies live in Git.
2.  **Automated**: Enforced by CI/CD and Admission Controllers.
3.  **Determininstic**: Same input + Same Policy = Same Decision.

---

## The Open Policy Agent (OPA)

OPA (pronounced "Oh-pa") is the industry standard general-purpose policy engine. It is NOT K8s specific; it works with Linux, Envoy, Terraform, etc.

**Architecture**:
```
Service (K8s API) ──▶ Query (JSON) ──▶ OPA Engine ◀── Policy (Rego)
                                          │
                      Decision (JSON) ◀───┘
                    (Allow/Deny/Reason)
```

**Gatekeeper**: The OPA controller specifically for Kubernetes Admission Control.

---

## Rego Language Basics

Rego is OPA's query language. It is declarative (like SQL).

### Example: Deny Pods using "Latest" tag

```rego
package k8s.admission

deny[msg] {
  # 1. Input is a Pod
  input.request.kind.kind == "Pod"
  
  # 2. Iterate over containers
  image := input.request.object.spec.containers[_].image
  
  # 3. Check if image ends with ":latest" or has no tag
  not contains(image, ":")
  msg := sprintf("Image '%v' has no tag", [image])
}

deny[msg] {
  input.request.kind.kind == "Pod"
  image := input.request.object.spec.containers[_].image
  endswith(image, ":latest")
  msg := sprintf("Image '%v' uses latest tag", [image])
}
```

### How Rego Works
-   **Rules (`deny[...]`)**: If the body is true, the header is generated.
-   **Implicit OR**: Multiple `deny` blocks mean "Deny if A OR Deny if B".
-   **Implicit AND**: Lines inside a block are ANDed together.

---

## Kyverno (Kubernetes Native)

OPA can be complex (Rego is hard). **Kyverno** is a K8s-native alternative that uses YAML.

**Pros**: Easier to learn. No new language.
**Cons**: K8s only.

### Example: Require Labels (Kyverno)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: enforce
  rules:
    - name: check-owner
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Label 'owner' is required"
        pattern:
          metadata:
            labels:
              owner: "?*"
```

### Mutation (Auto-fix)
Kyverno excels at mutating resources.
*Example*: "If imagePullPolicy is missing, set it to Always."

---

## Shift-Left Security

Don't wait for deployment to fail. Test policies in CI.

### Conftest
A utility to run OPA policies against static files (Terraform files, Dockerfiles, YAML).

**Pipeline Integration:**
```yaml
# .gitlab-ci.yml
policy_check:
  stage: test
  image: openpolicyagent/conftest
  script:
    - conftest test -p policy/ deployment.yaml
```

**Terraform Policy Example:**
```rego
# Deny S3 buckets without Versioning
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not resource.change.after.versioning.enabled
  msg := "S3 buckets must have versioning enabled"
}
```
