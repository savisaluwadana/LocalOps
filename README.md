# Local DevOps Playground

A comprehensive local environment for learning DevOps tools with in-depth theory and hands-on examples.

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

## 📚 Documentation

### Getting Started
| Doc | Content |
|-----|---------|
| [00-Getting Started](docs/00-getting-started.md) | Quick setup guide |
| [01-Overview](docs/01-overview.md) | Architecture diagram |
| [02-Prerequisites](docs/02-prerequisites.md) | Installation guide |

### Core DevOps Tools (In-Depth Theory + Examples)
| Doc | Topics Covered |
|-----|----------------|
| [03-Linux](docs/03-linux.md) | Kernel, processes, memory, networking, bash scripting |
| [04-Docker](docs/04-docker.md) | Namespaces, cgroups, networking, multi-stage builds |
| [05-Ansible](docs/05-ansible.md) | Inventory, playbooks, modules, Jinja2, roles |
| [06-Terraform](docs/06-terraform.md) | State, providers, modules, for_each, conditionals |
| [07-Jenkins](docs/07-jenkins.md) | Pipelines, agents, credentials, blue-green deploys |
| [08-Kubernetes](docs/08-kubernetes.md) | Architecture, pods, services, storage, secrets |

### Advanced Topics
| Doc | Topics Covered |
|-----|----------------|
| [09-Monitoring](docs/09-monitoring.md) | Prometheus, Grafana, PromQL |
| [10-GitOps](docs/10-gitops.md) | ArgoCD, sync policies |
| [11-Vault](docs/11-vault.md) | Secret management, dynamic credentials |
| [12-CI/CD Examples](docs/12-cicd-examples.md) | Production pipelines |
| [13-Databases](docs/13-databases.md) | PostgreSQL, MySQL, Redis |
| [14-Security](docs/14-security.md) | Network policies, TLS |
| [15-Troubleshooting](docs/15-troubleshooting.md) | Common issues |

### 🔗 Tool Integration
| Doc | Description |
|-----|-------------|
| [20-Integration Guide](docs/20-integration-guide.md) | **How all tools work together** with 5 real-world scenarios |

## 🛠 Playground

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
└── examples/        # Complete working application
    └── webapp/      # Flask + PostgreSQL + Redis + Prometheus
```

## 🎯 Example Project

Run a complete full-stack application:

```bash
cd playground/examples/webapp
docker compose up -d

# Access:
# - App: http://localhost:5000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000
```

This example includes:
- Flask app with Prometheus metrics
- PostgreSQL database
- Redis cache
- Jenkinsfile for CI/CD
- Kubernetes manifests
- Docker Compose for local dev

## 📋 Requirements

- **macOS** with Apple Silicon or Intel
- **OrbStack** (replaces Docker Desktop)
- **16GB RAM** recommended
- **20GB disk space**

## 🎓 Learning Path

1. **Linux** → Shell, filesystem, networking
2. **Docker** → Containers, images, networking
3. **Ansible** → Server configuration
4. **Terraform** → Infrastructure provisioning
5. **Jenkins** → CI/CD pipelines
6. **Kubernetes** → Container orchestration
7. **Monitoring** → Prometheus + Grafana
8. **GitOps** → ArgoCD deployments

## 📝 License

MIT