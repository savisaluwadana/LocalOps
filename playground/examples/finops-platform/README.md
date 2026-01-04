# FinOps Platform

Cloud cost management and optimization platform with budgeting, alerts, and recommendations.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              FINOPS PLATFORM                                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DATA COLLECTION                                        │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   AWS Cost      │  │   GCP Billing   │  │       Azure Cost                ││  │
│  │  │   Explorer      │  │   Export        │  │       Management                ││  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────────┬────────────────────┘│  │
│  └───────────┼───────────────────┬┴────────────────────────┘                     │  │
│              │                   │                                                │  │
│  ┌───────────▼───────────────────▼───────────────────────────────────────────────┐  │
│  │                         DATA WAREHOUSE                                         │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                      Cost Data Lake (BigQuery/Snowflake)                 │  │  │
│  │  │  • Normalized cost data across clouds                                   │  │  │
│  │  │  • Resource tagging and allocation                                      │  │  │
│  │  │  • Historical trends                                                    │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                         ANALYSIS & OPTIMIZATION                                │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Cost          │  │   Anomaly       │  │      Recommendations            ││  │
│  │  │   Allocation    │  │   Detection     │  │      Engine                     ││  │
│  │  │                 │  │                 │  │  • Right-sizing                 ││  │
│  │  │  Team/Project   │  │  Alerts for     │  │  • Reserved Instances           ││  │
│  │  │  Attribution    │  │  Spikes         │  │  • Spot/Preemptible             ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DASHBOARDS & REPORTING                                 │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Executive     │  │   Team          │  │       Budget                    ││  │
│  │  │   Dashboard     │  │   Breakdown     │  │       Tracking                  ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Cloud** - AWS, GCP, Azure cost aggregation
- **Cost Allocation** - Tag-based attribution to teams/projects
- **Budgets** - Set and track spending limits
- **Anomaly Detection** - Alert on unexpected cost spikes
- **Recommendations** - Right-sizing, reserved instances, spot savings
- **Showback/Chargeback** - Cost attribution reports

## Quick Start

```bash
# Deploy cost exporter
kubectl apply -k kubernetes/cost-exporter/

# Set up data pipeline
./scripts/setup-cost-pipeline.sh

# Access dashboard
kubectl port-forward svc/finops-dashboard 8080:80
```

## Cost Allocation Tags

```yaml
# Required tags for all resources
required_tags:
  - environment    # dev, staging, prod
  - team           # engineering, data, platform
  - project        # project-name
  - cost-center    # finance cost center
  - owner          # email of owner
```

## Budget Alerts

| Threshold | Action |
|-----------|--------|
| 50% | Email notification |
| 80% | Slack + Email |
| 100% | PagerDuty + Auto-scale down (optional) |

## Savings Recommendations

| Type | Typical Savings | Commitment |
|------|----------------|------------|
| Reserved Instances | 30-60% | 1-3 years |
| Savings Plans | 20-40% | 1-3 years |
| Spot Instances | 60-90% | No commitment |
| Right-sizing | 20-40% | No commitment |

## Monthly Reporting

Generated reports include:
- Total spend by cloud provider
- Cost trends vs previous month
- Top 10 costliest services
- Unused/idle resources
- Savings opportunities
