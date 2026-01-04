# Chaos Engineering

## Table of Contents
1.  [Principles of Chaos](#principles-of-chaos)
2.  [The Experiment Lifecycle](#the-experiment-lifecycle)
3.  [Tools (Chaos Mesh / Gremlin)](#tools-chaos-mesh--gremlin)
4.  [Game Days](#game-days)
5.  [Safeguards (The Big Red Button)](#safeguards-the-big-red-button)

---

## Principles of Chaos

**Chaos Engineering** is the discipline of experimenting on a system in order to build confidence in the system's capability to withstand turbulent conditions in production.

> "We break things on purpose to see how they break, so we can fix them before they break with customers watching."

### Core Principles
1.  **Define Steady State**: What does "Healthy" look like? (e.g., Error rate < 1%).
2.  **Hypothesize**: "If we kill the Database Primary, the Replica will promote in < 30s."
3.  **Vary Real-world Events**: Network latency, disk full, pod crash, datacenter outage.
4.  **Run Experiment**: Inject the fault.
5.  **Verify**: Did the hypothesis hold true? Didsteady state return?

---

## The Experiment Lifecycle

### 1. Scope
Start **small**. Don't nuke the entire production DB on day 1.
-   *Level 1*: A single non-critical pod in Staging.
-   *Level 5*: Random Availability Zone failure in Production.

### 2. Hypothesis
Must be falsifiable.
-   *Good*: "Latency will increase to 200ms but no 500 errors."
-   *Bad*: "The system will be fine."

### 3. Execution (The Attack)
Inject the fault reliably.

### 4. Analysis
-   **Detected?**: Did alerts fire?
-   **Mitigated?**: Did auto-scaling/circuit-breakers kick in?
-   **Recovery**: Did it self-heal?

---

## Tools (Chaos Mesh / Gremlin)

### Chaos Mesh (Kubernetes Native)
Open-source, CNCF project. Installs as a CRD/Controller.

**Example: Pod Kill**
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-example
spec:
  action: pod-kill
  mode: one
  selector:
    labelSelectors:
      app: nginx
  scheduler:
    cron: "@every 10m"
```

**Example: Network Latency (Traffic Control)**
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-delay
spec:
  action: delay
  mode: all
  selector:
    labelSelectors:
      app: payment-service
  delay:
    latency: "100ms"
    jitter: "10ms"
```

### Gremlin (SaaS)
Enterprise GUI. Easier to use, better reporting, safer (built-in abort buttons).

---

## Game Days

A strictly planned "Fire Drill" for Engineering.

**Roles**:
-   **Commander**: Runs the show.
-   **Attacker (Chaos Monkey)**: Injects the failure.
-   **Observer**: Watches graphs/logs.
-   **Scribe**: Writes down timeline.

**Scenario**:
"We are going to simulate a Redis failure during peak load."

**Outcome**:
Action items. "Our retry logic didn't work" or "Alerts took 5 minutes to fire."

---

## Safeguards (The Big Red Button)

**CRITICAL**: You must have a way to STOP the experiment immediately if things go wrong.
-   **Automatic Abort**: If Error Rate > 5%, stop chaos.
-   **Manual Abort**: One command to remove all chaos resources.
