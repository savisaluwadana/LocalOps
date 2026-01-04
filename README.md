# Local DevOps Playground

A comprehensive local environment with **18 hands-on projects** and in-depth documentation.

## 🚀 Quick Start

```bash
brew install orbstack terraform ansible kubectl helm
./scripts/verify-prereqs.sh
```

---

## 📚 Documentation

### Core DevOps Tools (In-Depth Theory)
| Doc | Content |
|-----|---------|
| [Linux](docs/03-linux.md) | Kernel, processes, networking, bash |
| [Docker](docs/04-docker.md) | Namespaces, cgroups, multi-stage |
| [Ansible](docs/05-ansible.md) | Playbooks, modules, Jinja2 |
| [Terraform](docs/06-terraform.md) | State, modules, patterns |
| [Jenkins](docs/07-jenkins.md) | Pipelines, agents |
| [Kubernetes](docs/08-kubernetes.md) | Architecture, objects |

### CI/CD Platforms (New!)
| Doc | Content |
|-----|---------|
| [**GitHub Actions**](docs/16-github-actions.md) | Workflows, matrix, reusable actions, self-hosted runners |
| [**GitLab CI/CD**](docs/17-gitlab-ci.md) | Pipelines, stages, templates, environments |

### Advanced Topics
| Doc | Content |
|-----|---------|
| [Monitoring](docs/09-monitoring.md) | Prometheus, Grafana |
| [GitOps](docs/10-gitops.md) | ArgoCD |
| [Vault](docs/11-vault.md) | Secret management |
| [Integration Guide](docs/20-integration-guide.md) | How tools work together |

---

## 🎯 18 Example Projects

### 🏢 Real-World Applications
| Project | Description | Start |
|---------|-------------|-------|
| **`ecommerce-platform/`** | Full microservices e-commerce (Products, Orders, Payments) + GitHub Actions + GitLab CI | `docker compose up -d` |
| **`pos-system/`** | Point of Sale with sales, inventory, reporting | `docker compose up -d` |
| **`inventory-management/`** | Warehouse, stock tracking, purchase orders | `docker compose up -d` |
| **`blog-platform/`** | Multi-tenant CMS with media, search | `docker compose up -d` |
| `microservices/` | 3 Node.js services + API Gateway | `docker compose up -d` |
| `webapp/` | Flask + PostgreSQL + Redis + Prometheus | `docker compose up -d` |

### 🚀 Deployment Strategies
| Project | Description |
|---------|-------------|
| `blue-green/` | Zero-downtime with traffic switching |
| `canary-deployment/` | Gradual rollout (10% → 100%) |
| `gitops-example/` | ArgoCD + Kustomize |
| `auto-scaling/` | Kubernetes HPA |

### 🔧 Infrastructure & CI/CD
| Project | Description |
|---------|-------------|
| `infra-automation/` | Terraform → Ansible |
| `database-migrations/` | Flyway SQL migrations |
| `cicd-pipeline/` | Jenkins + GitHub Actions |
| `api-gateway/` | Kong with rate limiting |

### 🧪 Testing & Observability
| Project | Description |
|---------|-------------|
| `load-testing/` | k6 (smoke, stress, spike) |
| `log-aggregation/` | ELK Stack |
| `chaos-engineering/` | Failure injection |
| `feature-flags/` | Unleash toggles |

---

## 📋 Requirements

- **macOS** with OrbStack
- **16GB RAM**, 40GB disk

## 📝 License
MIT