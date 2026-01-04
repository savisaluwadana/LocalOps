# The Complete DevOps & Platform Engineering Roadmap

Welcome to **LocalOps**. This documentation is designed to take you from a **complete beginner** to an **Advanced Platform Engineer**.

The roadmap is divided into **8 Phases**. It is recommended to follow them in order, as each phase builds upon the previous one.

---

## 🔰 Phase 1: The Foundation
*Before touching the cloud, you must understand the machine and how computers talk.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **Linux** | Shell, Permissions, Processes. The OS of the cloud. | [03-linux.md](03-linux.md) | `playground/linux/` |
| **Networking** | DNS, TCP/IP, OSI, VPCs. How data moves. | [27-networking.md](27-networking.md) | Use `dig`, `curl`, `netstat` |
| **Automation** | Python & Go for DevOps. Moving beyond Bash. | [29-automation.md](29-automation.md) | Write a health-check script |

---

## 📦 Phase 2: Containerization
*Stop saying "It works on my machine". Package your apps securely.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **Docker** | Images, Containers, Multi-stage builds. | [04-docker.md](04-docker.md) | `playground/examples` |
| **Databases** | Managing state in containers (SQL/NoSQL). | [13-databases.md](13-databases.md) | Run Postgres in Docker |

---

## 🏗️ Phase 3: Infrastructure as Code (IaC)
*Stop clicking buttons in the console. Define your world in text.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **Terraform** | Provisioning Infrastructure (The Standard). | [02-terraform.md](02-terraform.md) | `playground/examples/*/terraform` |
| **Ansible** | Configuration Management (Configuring VMs). | [05-ansible.md](05-ansible.md) | `playground/ansible/` |
| **Patterns** | Advanced Terraform modules & state usage. | [25-terraform-patterns.md](25-terraform-patterns.md) | Refactor into Modules |

---

## 🚀 Phase 4: CI/CD (Continuous Integration/Delivery)
*Automate the testing and delivery of your software.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **The Theory** | CI vs CD, Deployment Strategies (Blue/Green). | [03-cicd.md](03-cicd.md) | Draw a pipeline board |
| **Jenkins** | The classic, extendable CI server. | [07-jenkins.md](07-jenkins.md) | Set up a master/agent |
| **GitHub Actions**| The modern, integrated choice. | [16-github-actions.md](16-github-actions.md) | `.github/workflows/` |
| **GitLab CI** | Integrated DevOps Platform. | [17-gitlab-ci.md](17-gitlab-ci.md) | `.gitlab-ci.yml` |
| **CircleCI** | Cloud-native speed focus. | [18-circleci.md](18-circleci.md) | `.circleci/config.yml` |

---

## ☸️ Phase 5: Container Orchestration & GitOps
*Manage thousands of containers across clusters.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **Kubernetes** | Architecture, Pods, Services, Ingress. | [06-kubernetes.md](06-kubernetes.md) | `playground/examples/*/k8s` |
| **GitOps** | Infrastructure changes via Git PRs. | [10-gitops.md](10-gitops.md) | Install ArgoCD |
| **ArgoCD** | Declarative Continuous Delivery. | [19-argocd.md](19-argocd.md) | Sync an App |
| **Argo Workflows**| Orchestrating jobs/pipelines on K8s. | [20-argo-workflows.md](20-argo-workflows.md) | Run a DAG workflow |

---

## 🔭 Phase 6: Observability (SRE Level 1)
*You can't fix what you can't see.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **Monitoring** | The 3 Pillars (Metrics, Logs, Traces). | [09-monitoring.md](09-monitoring.md) | Setup ELK Stack |
| **Prometheus** | Storing time-series metrics. PromQL. | [26-prometheus-grafana.md](26-prometheus-grafana.md) | Scrape an endpoint |
| **Grafana** | Visualizing your data. | [26-prometheus-grafana.md](26-prometheus-grafana.md) | Build a Dashboard |
| **Troubleshooting**| Structured approach to debugging. | [15-troubleshooting.md](15-troubleshooting.md) | Break & Fix a Pod |

---

## 🔒 Phase 7: Security & Governance (DevSecOps)
*Security is everyone's job, not just the "Security Team".*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **Security 101** | DevSecOps, Shield-Right, Shift-Left. | [14-security.md](14-security.md) | Scan an image (Trivy) |
| **Vault** | Secrets Management (No passwords in git!). | [11-vault.md](11-vault.md) | Inject secrets to K8s |
| **Best Practices**| Hardening guide for Prods. | [24-security-best-practices.md](24-security-best-practices.md) | Audit an AWS account |

---

## 👑 Phase 8: Advanced Platform Engineering
*Building the platforms that developers build on.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **SRE** | SLOs, Error Budgets, Incident Mgmt. | [23-sre.md](23-sre.md) | Define an SLO |
| **Platform Eng** | IDPs, Golden Paths, Backstage. | [22-platform-engineering.md](22-platform-engineering.md) | Draw a Team Topology |
| **Service Mesh** | Istio/Linkerd, mTLS, Traffic Control. | [25-service-mesh.md](25-service-mesh.md) | Install Istio |
| **Cloud Patterns**| Microservices, CQRS, Saga. | [23-cloud-patterns.md](23-cloud-patterns.md) | Architect a System |
| **Serverless** | Event-Driven Architectures (Lambda/Kafka).| [28-serverless.md](28-serverless.md) | Design an EDA |
| **FinOps** | Cost Management & Optimization. | [30-finops.md](30-finops.md) | Estimate Project Cost |

---

## 🎓 Phase 9: The Masterclass (Staff Engineer Level)
*Understanding how the magic actually works (Kernel, Protocols, Consensus).*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **K8s Internals** | CNI, CSI, CRI, etcd, Operator Pattern. | [31-kubernetes-internals.md](31-kubernetes-internals.md) | Use `crictl` |
| **Linux Internals** | Namespaces, Cgroups, Syscalls, eBPF. | [32-linux-internals.md](32-linux-internals.md) | Use `strace` |
| **Distributed Sys** | CAP Theorem, Raft, Consistency Models. | [33-distributed-systems.md](33-distributed-systems.md) | Design an HA system |
| **DB Internals** | LSM vs B-Tree, Isolation Levels, Sharding. | [34-database-internals.md](34-database-internals.md) | Tune PostgreSQL |
| **Policy as Code** | OPA, Rego, Kyverno, Compliance. | [35-policy-as-code.md](35-policy-as-code.md) | Write OPA Policy |
| **System Design** | Availability, Multi-Region, Resiliency. | [36-system-design.md](36-system-design.md) | Architect DR Plan |

---

## 🧠 Phase 10: Chaos & Leadership (Principal Level)
*Technical excellence is not enough. You must lead.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **Chaos Eng** | Breaking things on purpose. Game Days. | [37-chaos-engineering.md](37-chaos-engineering.md) | Run Chaos Mesh |
| **Staff+ Skills** | RFCs, Influence, Mentorship. | [38-staff-plus-skills.md](38-staff-plus-skills.md) | Write an RFC |
| **The Future** | LLMOps, Wasm, GreenOps. | [39-future-trends.md](39-future-trends.md) | Run a Wasm App |

---

## 🤖 Phase 11: MLOps & AI Engineering (Specialization)
*Bridging the gap between Data Science and Operations.*

| Topic | Description | Theory | Practice |
|-------|-------------|--------|----------|
| **MLOps Theory** | Lifecycle, Feature Stores, Drift. | [40-mlops.md](40-mlops.md) | Build Churn Pipe |

---

## 🎮 Hands-on Projects
*Theory is nothing without practice. Check the `playground/examples` folder.*

1.  **Static Website**: Docker + Nginx.
2.  **3-Tier App**: React + Node + Postgres (Docker Compose).
3.  **K8s Deployment**: Deploy the 3-Tier App to Minikube.
4.  **CI/CD Pipeline**: Build & Push image on commit.
5.  **GitOps Sync**: Deploy via ArgoCD.
6.  **Monitoring**: Add Prometheus metrics to the Node App.

---
*Happy Learning!*
