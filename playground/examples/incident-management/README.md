# Incident Management Platform

Enterprise incident management with PagerDuty integration, automated runbooks, post-mortems, and SRE practices.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                       INCIDENT MANAGEMENT PLATFORM                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         DETECTION                                              │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │  Alertmanager   │  │   Datadog       │  │      Synthetic Monitors         ││  │
│  │  │  (Prometheus)   │  │   (APM)         │  │      (Uptime)                   ││  │
│  │  └────────┬────────┘  └────────┬────────┘  └────────────┬────────────────────┘│  │
│  └───────────┼───────────────────┬┴────────────────────────┘                     │  │
│              │                   │                                                │  │
│  ┌───────────▼───────────────────▼───────────────────────────────────────────────┐  │
│  │                    INCIDENT ROUTING                                            │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                       PagerDuty                                          │  │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────┐  │  │  │
│  │  │  │ Escalation  │  │  On-Call    │  │  Service    │  │   Urgency     │  │  │  │
│  │  │  │  Policies   │  │  Schedules  │  │  Directory  │  │   Rules       │  │  │  │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                    RESPONSE & REMEDIATION                                      │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Runbooks      │  │   Slack Bot     │  │       Auto-remediation          ││  │
│  │  │  (Automated)    │  │  (Coordination) │  │       (Ansible/K8s)             ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                    POST-INCIDENT                                               │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │  Post-mortems   │  │   RCA Template  │  │       Action Items              ││  │
│  │  │  (Blameless)    │  │   (5 Whys)      │  │       (JIRA/Linear)             ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Alert Routing** - PagerDuty/OpsGenie integration
- **On-Call Management** - Schedules and escalations
- **Runbook Automation** - Ansible-based auto-remediation
- **Incident Bot** - Slack bot for coordination
- **Status Pages** - Public and internal status
- **Post-mortems** - Blameless RCA templates
- **Metrics** - MTTR, MTTD tracking

## Quick Start

```bash
# Deploy incident bot
kubectl apply -k kubernetes/incident-bot/

# Configure PagerDuty
./scripts/setup-pagerduty.sh

# Deploy runbook executor
kubectl apply -f kubernetes/runbook-operator/
```

## Severity Levels

| Severity | Description | Response Time | Escalation |
|----------|-------------|---------------|------------|
| SEV1 | Critical outage | 5 min | Immediate to management |
| SEV2 | Major degradation | 15 min | 30 min to lead |
| SEV3 | Minor issue | 1 hour | Next business day |
| SEV4 | Low priority | 4 hours | None |

## On-Call Rotations

```yaml
rotations:
  - name: primary-oncall
    type: weekly
    participants:
      - user: alice@example.com
      - user: bob@example.com
      - user: charlie@example.com
    handoff_time: "09:00"
    timezone: "America/New_York"
    
  - name: secondary-oncall
    type: weekly
    start_delay: 7  # days after primary
```

## Runbook Example

```yaml
name: pod-crashloop-remediation
trigger:
  alert: KubePodCrashLooping
steps:
  - name: Gather diagnostics
    action: kubectl_exec
    command: kubectl describe pod {{ .pod }} -n {{ .namespace }}
    
  - name: Check recent events
    action: kubectl_exec
    command: kubectl get events -n {{ .namespace }} --sort-by='.lastTimestamp'
    
  - name: Attempt restart
    action: kubectl_exec
    command: kubectl rollout restart deployment/{{ .deployment }} -n {{ .namespace }}
    condition: "{{ .restart_count < 3 }}"
    
  - name: Scale down if persistent
    action: kubectl_exec
    command: kubectl scale deployment/{{ .deployment }} --replicas=0 -n {{ .namespace }}
    condition: "{{ .restart_count >= 3 }}"
    notify: true
```

## Metrics Tracked

| Metric | Target | Current |
|--------|--------|---------|
| MTTD (Mean Time to Detect) | < 5 min | 3.2 min |
| MTTA (Mean Time to Acknowledge) | < 10 min | 7.5 min |
| MTTR (Mean Time to Resolve) | < 1 hour | 45 min |
| SEV1 Incidents/Month | < 2 | 1.3 |
