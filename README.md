# Local DevOps Playground

A comprehensive local environment for learning DevOps with in-depth theory and **14 hands-on projects**.

## 🚀 Quick Start

```bash
brew install orbstack terraform ansible kubectl helm
./scripts/verify-prereqs.sh
./scripts/start-all.sh
```

## 📚 Documentation

| Core Tools | Advanced Topics |
|------------|-----------------|
| [Linux](docs/03-linux.md) - Kernel, processes, bash | [Monitoring](docs/09-monitoring.md) - Prometheus, Grafana |
| [Docker](docs/04-docker.md) - Containers, networking | [GitOps](docs/10-gitops.md) - ArgoCD |
| [Ansible](docs/05-ansible.md) - Playbooks, modules | [Vault](docs/11-vault.md) - Secret management |
| [Terraform](docs/06-terraform.md) - IaC, modules | [CI/CD](docs/12-cicd-examples.md) - Pipelines |
| [Jenkins](docs/07-jenkins.md) - Pipelines | [Security](docs/14-security.md) - Network policies |
| [Kubernetes](docs/08-kubernetes.md) - Orchestration | [**Integration Guide**](docs/20-integration-guide.md) |

---

## 🎯 14 Example Projects

### Application Deployment
| Project | Description | Start |
|---------|-------------|-------|
| `webapp/` | Flask + PostgreSQL + Redis + Prometheus | `docker compose up -d` → :5000 |
| `microservices/` | 3 Node.js services + API Gateway + MongoDB | `docker compose up -d` → :8080/api |
| `api-gateway/` | Kong with rate limiting, auth | `docker compose up -d` → :8000 |

### Deployment Strategies
| Project | Description | Start |
|---------|-------------|-------|
| `blue-green/` | Zero-downtime with traffic switching | `./scripts/switch.sh green` |
| `canary-deployment/` | Gradual rollout (10% → 100%) | `./scripts/canary.sh 25` |
| `gitops-example/` | ArgoCD + Kustomize overlays | `kubectl apply -f apps/` |
| `auto-scaling/` | Kubernetes HPA | `kubectl apply -f manifests/` |

### Infrastructure & Automation
| Project | Description | Start |
|---------|-------------|-------|
| `infra-automation/` | Terraform → Ansible | `terraform apply` + `ansible-playbook` |
| `database-migrations/` | Flyway with SQL migrations | `docker compose up -d` |
| `cicd-pipeline/` | Jenkins + GitHub Actions | `docker compose up -d` → :8080 |

### Testing & Observability
| Project | Description | Start |
|---------|-------------|-------|
| `load-testing/` | k6 (smoke, stress, spike tests) | `k6 run scripts/load.js` |
| `log-aggregation/` | ELK Stack | `docker compose up -d` → :5601 |
| `chaos-engineering/` | Failure injection experiments | `./scripts/chaos.sh kill-random` |
| `feature-flags/` | Unleash feature toggles | `docker compose up -d` → :4242 |

---

## 📋 Requirements

- **macOS** with OrbStack
- **16GB RAM**, 30GB disk

## 📝 License
MIT