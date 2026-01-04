# Local DevOps Playground

A comprehensive local environment with **23 hands-on projects** and in-depth documentation.

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

### CI/CD Platforms (Detailed)
| Doc | Content |
|-----|---------|
| [**GitHub Actions**](docs/16-github-actions.md) | Workflows, matrix, reusable actions, self-hosted runners |
| [**GitLab CI/CD**](docs/17-gitlab-ci.md) | Pipelines, stages, templates, environments |
| [**CircleCI**](docs/18-circleci.md) | Orbs, caching, parallelism, workspaces |

### Advanced Topics
| Doc | Content |
|-----|---------|
| [Monitoring](docs/09-monitoring.md) | Prometheus, Grafana |
| [GitOps](docs/10-gitops.md) | ArgoCD |
| [Vault](docs/11-vault.md) | Secret management |
| [Integration Guide](docs/20-integration-guide.md) | How tools work together |

---

## 🎯 23 Example Projects

### 🏢 Real-World Applications
| Project | Description |
|---------|-------------|
| **`ecommerce-platform/`** | Full e-commerce (Products, Orders, Payments) + GitHub Actions + GitLab CI |
| **`pos-system/`** | Point of Sale: sales, inventory, reports |
| **`inventory-management/`** | Warehouse, stock tracking, purchase orders |
| **`blog-platform/`** | Multi-tenant CMS, media, search |
| **`booking-system/`** | Appointments, distributed locks, notifications |
| **`url-shortener/`** | Base62 encoding, analytics, Redis cache |
| **`task-queue/`** | BullMQ workers, scheduling, dashboard |
| **`notification-service/`** | Email, SMS, push, webhooks |
| **`realtime-chat/`** | WebSocket, Redis PubSub, MongoDB |
| `microservices/` | 3 Node.js services + API Gateway |
| `webapp/` | Flask + PostgreSQL + Redis + Prometheus |

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
- **16GB RAM**, 50GB disk

## 📝 License
MIT