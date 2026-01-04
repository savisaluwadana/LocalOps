# Local DevOps Playground

A comprehensive local environment for learning DevOps tools with in-depth theory, hands-on examples, and complete projects.

## 🚀 Quick Start

```bash
# Install OrbStack (unified platform)
brew install orbstack

# Install CLI tools
brew install terraform ansible kubectl helm

# Verify installation
./scripts/verify-prereqs.sh

# Start the complete playground
./scripts/start-all.sh
```

## 📚 Documentation (In-Depth Theory)

### Getting Started
| Doc | Content |
|-----|---------|
| [00-Getting Started](docs/00-getting-started.md) | Quick setup guide |
| [01-Overview](docs/01-overview.md) | Architecture diagram |
| [02-Prerequisites](docs/02-prerequisites.md) | Installation guide |

### Core DevOps Tools
| Doc | Topics |
|-----|--------|
| [03-Linux](docs/03-linux.md) | Kernel, processes, memory, networking, bash |
| [04-Docker](docs/04-docker.md) | Namespaces, cgroups, networking, multi-stage builds |
| [05-Ansible](docs/05-ansible.md) | Inventory, playbooks, modules, Jinja2, roles |
| [06-Terraform](docs/06-terraform.md) | State, providers, modules, patterns |
| [07-Jenkins](docs/07-jenkins.md) | Pipelines, agents, credentials |
| [08-Kubernetes](docs/08-kubernetes.md) | Architecture, pods, services, storage |

### Advanced Topics
| Doc | Topics |
|-----|--------|
| [09-Monitoring](docs/09-monitoring.md) | Prometheus, Grafana, PromQL |
| [10-GitOps](docs/10-gitops.md) | ArgoCD, sync policies |
| [11-Vault](docs/11-vault.md) | Secret management |
| [12-CI/CD Examples](docs/12-cicd-examples.md) | Production pipelines |
| [13-Databases](docs/13-databases.md) | PostgreSQL, MySQL, Redis |
| [14-Security](docs/14-security.md) | Network policies, TLS |
| [15-Troubleshooting](docs/15-troubleshooting.md) | Common issues |
| [**20-Integration Guide**](docs/20-integration-guide.md) | **How all tools work together** |

---

## 🎯 Example Projects

### 1. Web Application (`examples/webapp/`)
Full-stack Flask app with PostgreSQL, Redis, Prometheus metrics.
```bash
cd playground/examples/webapp && docker compose up -d
# App: localhost:5000 | Grafana: localhost:3000
```

### 2. Microservices (`examples/microservices/`)
3 Node.js services (User, Product, Order) + API Gateway + MongoDB.
```bash
cd playground/examples/microservices && docker compose up -d
# Gateway: localhost:8080/api/users
```

### 3. Blue-Green Deployment (`examples/blue-green/`)
Zero-downtime deployments with traffic switching.
```bash
cd playground/examples/blue-green && docker compose up -d
./scripts/switch.sh green  # Switch traffic
```

### 4. Infrastructure Automation (`examples/infra-automation/`)
Terraform provisions → Ansible configures.
```bash
cd playground/examples/infra-automation/terraform
terraform init && terraform apply
cd ../ansible && ansible-playbook site.yml
```

### 5. Log Aggregation (`examples/log-aggregation/`)
ELK Stack (Elasticsearch, Logstash, Kibana).
```bash
cd playground/examples/log-aggregation && docker compose up -d
# Kibana: localhost:5601
```

### 6. CI/CD Pipeline (`examples/cicd-pipeline/`)
Jenkins + Docker Registry with GitHub Actions alternative.
```bash
cd playground/examples/cicd-pipeline && docker compose up -d
# Jenkins: localhost:8080
```

### 7. GitOps with ArgoCD (`examples/gitops-example/`)
Kubernetes deployments via Git.
```bash
kubectl apply -f playground/examples/gitops-example/apps/guestbook.yaml
```

---

## 🛠 Playground Components

```
playground/
├── orbstack/        # Linux VM management
├── terraform/       # Infrastructure as Code
├── ansible/         # Configuration management
├── jenkins/         # CI/CD server
├── kubernetes/      # K8s manifests
├── monitoring/      # Prometheus + Grafana
├── vault/           # Secret management
├── databases/       # PostgreSQL, MySQL, Redis
├── argocd/          # GitOps examples
└── examples/        # Complete working projects
    ├── webapp/          # Flask + PostgreSQL + Redis
    ├── microservices/   # Node.js microservices
    ├── blue-green/      # Zero-downtime deployment
    ├── infra-automation/# Terraform + Ansible
    ├── log-aggregation/ # ELK Stack
    ├── cicd-pipeline/   # Jenkins + GitHub Actions
    └── gitops-example/  # ArgoCD + Kustomize
```

---

## 📋 Requirements

- **macOS** with Apple Silicon or Intel
- **OrbStack** (replaces Docker Desktop)
- **16GB RAM** recommended
- **30GB disk space**

## 🎓 Learning Path

1. **Linux** → Shell, filesystem, networking
2. **Docker** → Containers, images, Compose
3. **Ansible** → Server configuration
4. **Terraform** → Infrastructure provisioning
5. **Jenkins** → CI/CD pipelines
6. **Kubernetes** → Container orchestration
7. **Monitoring** → Prometheus + Grafana
8. **GitOps** → ArgoCD deployments

## 📝 License

MIT