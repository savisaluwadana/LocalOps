# FinOps and Cost Management

## Table of Contents

1. [What is FinOps?](#what-is-finops)
2. [The Iron Triangle of Cost](#the-iron-triangle-of-cost)
3. [Cloud Cost Models](#cloud-cost-models)
4. [Cost Optimization Strategies](#cost-optimization-strategies)
5. [Tagging Strategy](#tagging-strategy)
6. [Tools](#tools)

---

## What is FinOps?

**FinOps** (Financial Operations) is an operational framework and cultural practice that brings financial accountability to the variable spend model of cloud.

> "Engineering enables speed; Finance enables efficiency. FinOps enables both."

### The Phases

1.  **Inform**: Visualization, allocation, benchmarking. "Where is the money going?"
2.  **Optimize**: Reducing waste, rightsizing, reserving. "How can we spend less?"
3.  **Operate**: Continuous improvement, automation. "How do we make it process?"

---

## The Iron Triangle of Cost

When optimizing, you trade off between three constraints:

1.  **Speed**: How fast can we deliver features?
2.  **Quality**: Reliability, performance.
3.  **Cost**: The bottom line.

**Cheap + Fast = Low Quality**
**Good + Fast = Expensive**
**Good + Cheap = Slow**

---

## Cloud Cost Models

### 1. On-Demand
-   **Pay as you go**.
-   Most expensive.
-   Best for: Spiky workloads, short-term experiments.

### 2. Reserved Instances (RIs) / Savings Plans
-   **Commitment**: 1 or 3 years.
-   **Discount**: Up to 72% off.
-   **Best for**: Steady-state usage (Database, Core App Servers).

### 3. Spot Instances
-   **Bid for unused capacity**.
-   **Discount**: Up to 90% off.
-   **Risk**: Instance can be terminated with 2 minutes notice.
-   **Best for**: Stateless, fault-tolerant, batch processing, CI/CD runners.

---

## Cost Optimization Strategies

### 1. Rightsizing
Matching instance types/sizes to workload performance and capacity requirements at the lowest possible cost.
-   *Example*: Moving from `t3.xlarge` (4 vCPU, 16GB) to `t3.medium` (2 vCPU, 4GB) if average CPU is 5%.

### 2. Eliminating Waste
-   **Orphaned Volumes**: Delete EBS volumes not attached to instances.
-   **Old Snapshots**: Lifecycle policies to delete snapshots > 30 days.
-   **Unattached IPs**: Release Elastic IPs not in use.
-   **Development Hours**: Turn off Dev environments at night (AWS Instance Scheduler).

### 3. Storage Tiers
Move infrequent data to cheaper storage classes.
-   **S3 Standard**: $0.023/GB
-   **S3 Infrequent Access**: $0.0125/GB
-   **S3 Glacier**: $0.004/GB

### 4. Data Transfer
-   Avoid cross-region traffic.
-   Use VPC Endpoints (PrivateLink) instead of NAT Gateways for S3/DynamoDB (NAT Gateway processes data at cost).
-   Use CloudFront (CDN) to offload egress traffic.

---

## Tagging Strategy

"You can't optimize what you can't measure."

**Allocation Tags**:
-   `CostCenter`: "Marketing", "Engineering"
-   `Owner`: "s.smith@company.com"
-   `Environment`: "Prod", "Dev", "Staging"
-   `Application`: "PaymentService", "Frontend"

**Automation Tags**:
-   `Schedule`: "BusinessHoursOnly"
-   `Backup`: "Daily"

---

## Tools

### Native
-   **AWS Cost Explorer**: Visualization.
-   **AWS Budgets**: Alerts when spending exceeds threshold.
-   **Azure Cost Management**.
-   **GCP Billing**.

### Third-Party
-   **CloudHealth (VMware)**.
-   **CloudZero**.
-   **Kubecost**: Specifically for Kubernetes namespace/pod cost attribution.
-   **Infracost**: Estimate Terraform cost **before** deploy (Pull Request comment).

### Example: Infracost Output

```
Project: my-infrastructure

+ aws_instance.web_server
  +$38.00/mo
    + Instance usage (Linux/UNIX, t3.medium): $30.00
    + Storage (gp3, 100GB): $8.00

Monthly cost change: +$38.00
```
