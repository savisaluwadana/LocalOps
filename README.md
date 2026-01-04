# Local DevOps Playground

A comprehensive local environment for learning and practicing DevOps tools: Linux, Docker, Ansible, Terraform, Jenkins, Kubernetes, and more.

## 🚀 Quick Start

```bash
# Install OrbStack
brew install orbstack

# Install CLI tools
brew install terraform ansible kubectl helm

# Verify installation
chmod +x scripts/verify-prereqs.sh
./scripts/verify-prereqs.sh

# Start everything
chmod +x scripts/start-all.sh
./scripts/start-all.sh
```

## 📚 Documentation

### Core Tools
| Guide | Description |
|-------|-------------|
| [Getting Started](docs/00-getting-started.md) | Setup and first steps |
| [Architecture](docs/01-overview.md) | How everything fits together |
| [Prerequisites](docs/02-prerequisites.md) | Installation requirements |

### DevOps Fundamentals
| Guide | Description |
|-------|-------------|
| [Linux](docs/03-linux.md) | Filesystem, commands, scripting |
| [Docker](docs/04-docker.md) | Containers, images, Compose |
| [Ansible](docs/05-ansible.md) | Configuration management |
| [Terraform](docs/06-terraform.md) | Infrastructure as Code |
| [Jenkins](docs/07-jenkins.md) | CI/CD pipelines |
| [Kubernetes](docs/08-kubernetes.md) | Container orchestration |

### Advanced Topics
| Guide | Description |
|-------|-------------|
| [Monitoring](docs/09-monitoring.md) | Prometheus & Grafana |
| [GitOps](docs/10-gitops.md) | ArgoCD deployment |
| [Vault](docs/11-vault.md) | Secret management |
| [CI/CD Examples](docs/12-cicd-examples.md) | Production pipelines |
| [Databases](docs/13-databases.md) | PostgreSQL, MySQL, Redis |
| [Security](docs/14-security.md) | Network policies, TLS |
| [Troubleshooting](docs/15-troubleshooting.md) | Common issues & fixes |

## 🛠 Playground

Ready-to-use configurations:

```
playground/
├── orbstack/       # Linux VM instructions
├── terraform/      # Docker provisioning
├── ansible/        # Server configuration
├── jenkins/        # CI/CD server
├── kubernetes/     # K8s manifests
├── monitoring/     # Prometheus + Grafana
├── vault/          # Secret management
├── databases/      # PostgreSQL, MySQL, Redis
└── argocd/         # GitOps examples
```

## 🎯 Services (After Start)

| Service | URL | Credentials |
|---------|-----|-------------|
| Linux VM | `ssh playground-vm` | - |
| Grafana | http://localhost:3000 | admin/admin123 |
| Prometheus | http://localhost:9090 | - |
| Jenkins | http://localhost:8080 | (see logs) |
| Vault | http://localhost:8200 | root |
| pgAdmin | http://localhost:5050 | admin@local.com/admin123 |
| Nginx | http://localhost:8000 | - |

## 📋 Requirements

- **macOS** with Apple Silicon or Intel
- **OrbStack** (replaces Docker Desktop + VirtualBox)
- **8GB RAM** minimum (16GB recommended)
- **20GB disk space**

## 🎓 Learning Path

1. **Linux** → Practice in OrbStack VM
2. **Docker** → Build and run containers
3. **Ansible** → Configure VMs automatically
4. **Terraform** → Provision resources as code
5. **Jenkins** → Create CI/CD pipelines
6. **Kubernetes** → Orchestrate containers
7. **Monitoring** → Observe with Prometheus/Grafana
8. **GitOps** → Deploy with ArgoCD

## 📝 License

MIT