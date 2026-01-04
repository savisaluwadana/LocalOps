# Local DevOps Playground

A comprehensive local environment with **31 hands-on projects** and in-depth documentation.

## 🚀 Quick Start

```bash
brew install orbstack terraform ansible kubectl helm
./scripts/verify-prereqs.sh
```

---

## 📚 Documentation

### Core DevOps Tools
| Doc | Content |
|-----|---------|
| [Linux](docs/03-linux.md) | Kernel, processes, networking |
| [Docker](docs/04-docker.md) | Namespaces, cgroups, multi-stage |
| [Ansible](docs/05-ansible.md) | Playbooks, modules, Jinja2 |
| [Terraform](docs/06-terraform.md) | State, modules, patterns |
| [Jenkins](docs/07-jenkins.md) | Pipelines, agents |
| [Kubernetes](docs/08-kubernetes.md) | Architecture, objects |

### CI/CD Platforms
| Doc | Content |
|-----|---------|
| [GitHub Actions](docs/16-github-actions.md) | Workflows, matrix, reusable actions |
| [GitLab CI/CD](docs/17-gitlab-ci.md) | Pipelines, stages, templates |
| [CircleCI](docs/18-circleci.md) | Orbs, caching, parallelism |

---

## 🎯 31 Example Projects

### 🏢 Real-World Applications (15)
| Project | Description |
|---------|-------------|
| `ecommerce-platform/` | Full e-commerce + GitHub Actions + GitLab CI |
| `pos-system/` | Point of Sale: sales, inventory, reports |
| `inventory-management/` | Warehouse, stock tracking |
| `blog-platform/` | Multi-tenant CMS |
| `booking-system/` | Appointments, distributed locks |
| `url-shortener/` | Base62, analytics, Redis cache |
| `task-queue/` | BullMQ workers, scheduling |
| `notification-service/` | Email, SMS, push, webhooks |
| `realtime-chat/` | WebSocket, Redis PubSub |
| `file-storage/` | Multipart uploads, CDN |
| `payment-gateway/` | Stripe, PayPal integration |
| `auth-service/` | JWT, OAuth, MFA |
| `email-service/` | Templates, async delivery |
| `search-service/` | Elasticsearch full-text |
| `microservices/` | 3 Node.js services + Gateway |

### 🔧 Infrastructure Services (5)
| Project | Description |
|---------|-------------|
| `api-gateway/` | Kong rate limiting |
| `rate-limiter/` | Redis distributed limiting |
| `service-discovery/` | Consul + Fabio LB |
| `metrics-dashboard/` | Prometheus + Grafana |
| `webapp/` | Flask + PostgreSQL + Redis |

### 🚀 Deployment Strategies (4)
| Project | Description |
|---------|-------------|
| `blue-green/` | Zero-downtime switching |
| `canary-deployment/` | Gradual rollout |
| `gitops-example/` | ArgoCD + Kustomize |
| `auto-scaling/` | Kubernetes HPA |

### 🛠 DevOps & CI/CD (4)
| Project | Description |
|---------|-------------|
| `infra-automation/` | Terraform → Ansible |
| `database-migrations/` | Flyway SQL |
| `cicd-pipeline/` | Jenkins + GitHub Actions |
| `log-aggregation/` | ELK Stack |

### 🧪 Testing & Resilience (3)
| Project | Description |
|---------|-------------|
| `load-testing/` | k6 performance tests |
| `chaos-engineering/` | Failure injection |
| `feature-flags/` | Unleash toggles |

---

## 📋 Requirements

- **macOS** with OrbStack  
- **16GB RAM**, 60GB disk

## 📝 License
MIT