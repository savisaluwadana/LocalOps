# Site Reliability Engineering (SRE) Guide

## Table of Contents

1. [SRE Fundamentals](#sre-fundamentals)
2. [SLIs, SLOs, and SLAs](#slis-slos-and-slas)
3. [Error Budgets](#error-budgets)
4. [Incident Management](#incident-management)
5. [Toil Reduction](#toil-reduction)
6. [Monitoring and Observability](#monitoring-and-observability)
7. [Capacity Planning](#capacity-planning)

---

## SRE Fundamentals

**Site Reliability Engineering (SRE)** is a discipline that incorporates aspects of software engineering and applies them to infrastructure and operations problems.

> "Hope is not a strategy." - Ben Treynor Sloss

### Core Principles

1.  **Embracing Risk**: Reliability is not 100%. Aim for "reliable enough".
2.  **Service Level Objectives**: Defined targets for reliability.
3.  **Eliminating Toil**: Automating repetitive work.
4.  **Monitoring**: Measuring everything.
5.  **Automation**: Automating this year's job away.
6.  **Release Engineering**: Safe, reliable release.
7.  **Simplicity**: Systems should be as simple as possible.

---

## SLIs, SLOs, and SLAs

### Service Level Indicator (SLI)
A quantitative measure of some aspect of the level of service that is provided.
- **Latency**: Time to process a request (ms).
- **Availability**: Ratio of successful requests to total requests.
- **Error Rate**: Ratio of errors to total requests.
- **Throughput**: Requests per second.

### Service Level Objective (SLO)
A target value or range of values for a service level that is measured by an SLI.
- "99.9% of requests in the last 28 days successfully return 200 OK."
- "99% of requests complete in under 100ms."

### Service Level Agreement (SLA)
A contract with the user that includes consequences (financial penalty) if the SLO is not met. SREs care about SLOs; Lawyers care about SLAs.

---

## Error Budgets

The **Error Budget** is 100% minus the SLO. It represents the amount of unreliability you can tolerate.

If SLO is 99.9%, Error Budget is 0.1%.

### How to use Error Budgets

- **Budget Remaining**: Innovation mode. Ship features, experiment, take risks.
- **Budget Exhausted**: Stability mode. Freeze feature launches, focus on reliability, fix bugs.

### Calculation Example

**Availability SLO: 99.9%** (Three Nines)
- **Downtime per year**: 8h 46m
- **Downtime per month**: 43m 50s
- **Downtime per week**: 10m 5s

**Availability SLO: 99.99%** (Four Nines)
- **Downtime per year**: 52m 36s
- **Downtime per month**: 4m 23s

---

## Incident Management

### The Lifecycle of an Incident

1.  **Detection**: Monitoring alerts or user reports.
2.  **Response**: On-call engineer acknowledges.
3.  **Mitigation**: Stop the bleeding (rollback, failover). Priority 1.
4.  **Resolution**: Fix the root cause.
5.  **Post-Mortem**: Learn and prevent recurrence.

### Incident Roles (ICS - Incident Command System)
- **Incident Commander (IC)**: In charge. managing the incident, not fixing it.
- **Operations Lead**: The one fixing the technical issue.
- **Comms Lead**: Updates stakeholders/customers.
- **Scribe**: Records timeline and decisions.

### Blameless Post-Mortems

A written record of an incident, its impact, actions taken, and the root cause. Crucial: **Avoid Blame**. Focus on process/system failure, not human error.

**Key Sections:**
- Summary
- Impact
- Timeline
- Root Cause Analysis (5 Whys)
- Action Items (Preventative measures)

---

## Toil Reduction

**Toil** is work that is:
- Manual
- Repetitive
- Automatable
- Tactical
- No enduring value
- Scales linearly with service growth

**Goal**: SREs should spend max 50% time on Ops (Toil + On-call) and min 50% on Engineering (Automation, Reliability features).

### Identifying Toil
- Manually running scripts to fix data.
- Handling predictable alerts.
- Creating accounts manually.
- Scaling servers manually.

---

## Operations vs SRE

| Traditional Ops | SRE |
|-----------------|-----|
| Manual changes | Infrastructure as Code |
| "Keep it running" | "Manage Risk" |
| Ad-hoc monitoring | SLO-based monitoring |
| Failure is bad | Failure is learning |
| Siloed | Shared ownership |

---

## Capacity Planning

Forecasting future resource needs based on organic growth and events.

1.  **Organic Growth**: Trend analysis (e.g., +10% users per month).
2.  **Inorganic Growth**: Product launches, marketing campaigns, Black Friday.

**Load Testing**:
- Stress testing (Limit discovery)
- Soak testing (Long duration)
- Spike testing (Sudden bursts)
