# Disaster Recovery Platform

Multi-region disaster recovery with automated failover, data replication, and business continuity.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         DISASTER RECOVERY PLATFORM                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────────────┐  │
│  │      PRIMARY REGION (US-EAST)   │  │      SECONDARY REGION (US-WEST)         │  │
│  │  ┌───────────────────────────┐  │  │  ┌─────────────────────────────────┐   │  │
│  │  │     Kubernetes Cluster    │  │  │  │     Kubernetes Cluster          │   │  │
│  │  │  ┌─────────┐ ┌─────────┐  │  │  │  │  ┌─────────┐ ┌─────────┐        │   │  │
│  │  │  │ Service │ │ Service │  │  │  │  │  │ Service │ │ Service │        │   │  │
│  │  │  │  (3x)   │ │  (3x)   │  │◄─┼──┼──┼─▶│  (3x)   │ │  (3x)   │        │   │  │
│  │  │  └─────────┘ └─────────┘  │  │  │  │  └─────────┘ └─────────┘        │   │  │
│  │  └───────────────────────────┘  │  │  └─────────────────────────────────┘   │  │
│  │                                  │  │                                        │  │
│  │  ┌───────────────────────────┐  │  │  ┌─────────────────────────────────┐   │  │
│  │  │     Database (Primary)    │  │  │  │     Database (Replica)          │   │  │
│  │  │  PostgreSQL with Patroni  │◄─┼──┼──┼─▶ PostgreSQL Streaming Replica  │   │  │
│  │  └───────────────────────────┘  │  │  └─────────────────────────────────┘   │  │
│  │                                  │  │                                        │  │
│  │  ┌───────────────────────────┐  │  │  ┌─────────────────────────────────┐   │  │
│  │  │     Object Storage (S3)   │  │  │  │     Object Storage (S3)         │   │  │
│  │  │  Cross-Region Replication │◄─┼──┼──┼─▶ Cross-Region Replication      │   │  │
│  │  └───────────────────────────┘  │  │  └─────────────────────────────────┘   │  │
│  └─────────────────────────────────┘  └─────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                           GLOBAL SERVICES                                      │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │  Route 53 /     │  │   CloudFlare    │  │       Velero                    ││  │
│  │  │  Traffic Manager│  │   (Global CDN)  │  │    (Backup/Restore)             ││  │
│  │  │  (DNS Failover) │  │                 │  │                                 ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Region Active-Passive** - Hot standby in secondary region
- **Database Replication** - PostgreSQL streaming replication with Patroni
- **Object Storage Sync** - S3 Cross-Region Replication
- **DNS Failover** - Route 53 health checks and automatic failover
- **Kubernetes Backup** - Velero for cluster state and persistent volumes
- **Automated Runbooks** - Ansible playbooks for DR procedures
- **Chaos Testing** - Regular DR drills with Litmus Chaos

## Recovery Objectives

| Tier | RTO | RPO | Examples |
|------|-----|-----|----------|
| Tier 1 | 5 min | 0 | Payment, Auth |
| Tier 2 | 30 min | 5 min | Orders, Inventory |
| Tier 3 | 4 hours | 1 hour | Reports, Analytics |
| Tier 4 | 24 hours | 24 hours | Batch jobs |

## Quick Start

```bash
# Deploy primary region
cd terraform/primary
terraform apply

# Deploy secondary region
cd terraform/secondary
terraform apply

# Configure replication
./scripts/setup-replication.sh

# Test failover
./scripts/failover-drill.sh --dry-run
```

## Failover Procedures

1. **Automated**: DNS health check fails → Route 53 failover
2. **Manual**: Run `./scripts/failover.sh --region us-west-2`
3. **Fallback**: Run `./scripts/fallback.sh` after recovery

## Backup Schedule

| Resource | Frequency | Retention |
|----------|-----------|-----------|
| Database | 15 min (WAL) | 30 days |
| Kubernetes | Daily | 90 days |
| Object Storage | Real-time | Versioning |
| Configurations | On change | Git history |
