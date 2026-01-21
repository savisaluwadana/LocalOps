# LocalOps Platform Engineering Bootcamp: The Complete Curriculum

## 🎓 Introduction
Welcome to the **LocalOps Bootcamp**. This is not just a list of folders; it is a structured, 8-week curriculum designed to take you from **Zero to Staff Engineer** level.

**Philosophy**: You learn by doing. You master by fixing.
**Prerequisite**:
*   Docker Desktop (or OrbStack/Rancher Desktop).
*   Visual Studio Code.
*   `kubectl`, `helm`, `jq` installed on your machine.
*   Basic familiarity with the terminal.

---

## 🗓 Week 1: The Container Foundation
**Goal**: Stop thinking in "servers" and start thinking in "services".

### Theory
*   **Containers vs VMs**: Shared kernel, isolation namespaces.
*   **Networking**: Service discovery, bridge networks.
*   **Persistence**: Ephemeral filesystems vs Volumes.

### Labs
1.  **Day 1: "Hello World"**
    *   **Project**: `playground/examples/webapp`
    *   **Task**: Build the Dockerfile. Run it mapping port 8080:80. Use `curl` to see the HTML.
    *   **Challenge**: Change the HTML and verify the change *without* rebuilding the image (Hint: Bind Mounts).

2.  **Day 2: The Trinity (App + DB + Cache)**
    *   **Project**: `playground/examples/inventory-management`
    *   **Task**: Examine `docker-compose.yml`. Notice the `depends_on`. Bring it up.
    *   **Challenge**: Connect to the Postgres container manually using `docker exec` and run a SQL query.

3.  **Day 3: Microservices Communication**
    *   **Project**: `playground/examples/microservices`
    *   **Task**: Understand how "Service A" calls "Service B" by hostname, not IP.
    *   **Challenge**: Scale "Service B" to 3 replicas (`docker-compose up -d --scale service-b=3`). Check logs to see load balancing.

---

## 🗓 Week 2: Orchestration & Infrastructure as Code
**Goal**: Manage fleets of containers, not individual ones.

### Theory
*   **Kubernetes**: Pods, Deployments, Services, Ingres.
*   **Declarative vs Imperative**: "I want 3 replicas" vs "Start 3 servers".

### Labs
1.  **Day 1: First Deployment**
    *   **Project**: `playground/examples/gitops-example` (Manifests folder)
    *   **Task**: Apply the `deployment.yaml` and `service.yaml` to your local K8s cluster.
    *   **Challenge**: Delete a Pod manually (`kubectl delete pod ...`) and watch K8s recreate it.

2.  **Day 2: The Helm Chart**
    *   **Project**: `playground/examples/ecommerce-platform` (Convert to Helm)
    *   **Task**: This project is in docker-compose. Your task is to write a simple Helm chart to deploy it to K8s.

3.  **Day 3: Infrastructure Automation**
    *   **Project**: `playground/examples/infra-automation`
    *   **Task**: Run the Terraform (or mock equivalent) to understand how cloud resources are provisioned.

---

## 🗓 Week 3: CI/CD & GitOps
**Goal**: Automate the path from "git push" to Production.

### Theory
*   **CI**: Lint, Build, Test, Push Image.
*   **CD**: Sync manifest to cluster (GitOps).

### Labs
1.  **Day 1: The Pipeline**
    *   **Project**: `playground/examples/cicd-pipeline`
    *   **Task**: Simulate a Jenkins/GitHub Actions pipeline. Run the build script.
    *   **Challenge**: Add a "linting" failure intentionally and verify the pipeline stops.

2.  **Day 2: GitOps sync**
    *   **Project**: `playground/examples/gitops-fleet`
    *   **Task**: Install ArgoCD (if available in playground or mock). Point it to a repo.
    *   **Challenge**: Change the replica count in Git, and watch the cluster update automatically.

---

## 🗓 Week 4: Observability (The "Eyes")
**Goal**: Understand *why* it broke, not just *that* it broke.

### Theory
*   **Logs**: "What happened?" (ELK/Loki).
*   **Metrics**: "What is happening?" (Prometheus).
*   **Traces**: "Where did it happen?" (Jaeger/Tempo).

### Labs
1.  **Day 1: Metrics**
    *   **Project**: `playground/examples/metrics-dashboard`
    *   **Task**: Spin up Prometheus/Grafana. Import a dashboard.
    *   **Challenge**: Create a custom alert: "Fire if Memory > 80%".

2.  **Day 2: Logging**
    *   **Project**: `playground/examples/log-management`
    *   **Task**: Deploy the Loki stack. Generate logs from `webapp`.
    *   **Challenge**: Use LogQL to search for "error".

3.  **Day 3: Distributed Tracing**
    *   **Project**: `playground/examples/tracing-service`
    *   **Task**: Trace a request across 3 microservices. Find the latency bottleneck.

---

## 🗓 Week 5: Reliability & Chaos
**Goal**: Build systems that survive failure.

### Theory
*   **SLO/SLA**: Service Level Objectives.
*   **Chaos Engineering**: Breaking things on purpose.

### Labs
1.  **Day 1: Chaos**
    *   **Project**: `playground/examples/chaos-engineering`
    *   **Task**: Run Chaos Mesh (or script). Kill the database pod.
    *   **Observation**: Does the app show a friendly error or crash?

2.  **Day 2: Auto-scaling**
    *   **Project**: `playground/examples/auto-scaling`
    *   **Task**: Generate load. Watch HPA scale pods from 1 to 10.
    *   **Challenge**: Tweak the CPU threshold.

---

## 🗓 Week 6: Security & Governance
**Goal**: Move fast without leaking credentials.

### Labs
1.  **Day 1: Secrets Management**
    *   **Project**: `playground/examples/secrets-rotation`
    *   **Task**: Replace hardcoded passwords with Vault lookups.

2.  **Day 2: Policies**
    *   **Project**: `playground/examples/compliance-platform`
    *   **Task**: Use OPA to block any deployment that doesn't have an "owner" label.

3.  **Day 3: Supply Chain**
    *   **Project**: `playground/examples/supply-chain-security`
    *   **Task**: Sign your image. Configure your cluster to reject unsigned images.

---

## 🗓 Week 7: Advanced Traffic Management
**Goal**: Control the flow using Service Mesh and API Gateways.

### Labs
1.  **Day 1: The Gateway**
    *   **Project**: `playground/examples/api-management`
    *   **Task**: Configure Kong. Add an API Key authentication plugin.

2.  **Day 2: Service Mesh**
    *   **Project**: `playground/examples/service-mesh`
    *   **Task**: Deploy Istio. Configure a "Canary Deployment" (90% traffic to v1, 10% to v2).

---

## 🗓 Week 8: The Domain Specialist (FinOps, MLOps, Data)
**Goal**: Apply platform engineering to specific business domains.

### Labs
1.  **FinOps**: `playground/examples/finops-platform` - Find wasted resources.
2.  **MLOps**: `playground/examples/mlops-platform` - Serve an ML model.
3.  **Data**: `playground/examples/streaming-analytics` - Build a Kafka pipeline.

---

## 🏆 Graduation Capstone
**Project**: `container-orchestration`

**Your Final Mission**:
1.  Deploy a multi-node Kubernetes cluster (using KinD or k3d).
2.  Install the **Observability Stack** (Week 4).
3.  Install the **Service Mesh** (Week 7).
4.  Deploy the **E-Commerce Platform** (Week 1).
5.  Set up **Chaos Monkey** (Week 5) to kill services randomly.
6.  Ensure the E-Commerce platform stays online (99.9% availability).

**Pass/Fail**: If you can buy a "product" on the e-commerce site while Chaos Monkey is killing pods, you pass.
