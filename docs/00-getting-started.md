# Getting Started with LocalOps

## Welcome to LocalOps

**LocalOps** is a comprehensive DevOps learning playground designed to help you master modern infrastructure and deployment practices through hands-on examples.

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- A terminal/shell
- Basic command line knowledge

### Clone the Repository

```bash
git clone https://github.com/your-org/localops.git
cd localops
```

### Explore the Structure

```
localops/
├── docs/                 # Documentation (you are here)
├── playground/
│   └── examples/        # Hands-on projects
├── scripts/             # Helper scripts
└── README.md
```

## Learning Path

### Beginner Path

| Order | Topic | Documentation |
|-------|-------|---------------|
| 1 | Linux Basics | [03-linux.md](03-linux.md) |
| 2 | Docker Fundamentals | [04-docker.md](04-docker.md) |
| 3 | Git and CI/CD | [03-cicd.md](03-cicd.md) |
| 4 | Basic Monitoring | [09-monitoring.md](09-monitoring.md) |

### Intermediate Path

| Order | Topic | Documentation |
|-------|-------|---------------|
| 1 | Kubernetes | [06-kubernetes.md](06-kubernetes.md) |
| 2 | Infrastructure as Code | [02-terraform.md](02-terraform.md) |
| 3 | Configuration Management | [05-ansible.md](05-ansible.md) |
| 4 | GitOps | [10-gitops.md](10-gitops.md) |

### Advanced Path

| Order | Topic | Documentation |
|-------|-------|---------------|
| 1 | Security Best Practices | [14-security.md](14-security.md) |
| 2 | Secrets Management | [11-vault.md](11-vault.md) |
| 3 | Cloud Patterns | [23-cloud-patterns.md](23-cloud-patterns.md) |

## Running Examples

Most examples can be started with Docker Compose:

```bash
cd playground/examples/<example-name>
docker-compose up -d
```

Check the README in each example for specific instructions.

## Documentation Overview

### Core Technologies

| Document | Description |
|----------|-------------|
| [Docker](04-docker.md) | Containerization fundamentals |
| [Kubernetes](06-kubernetes.md) | Container orchestration |
| [Terraform](02-terraform.md) | Infrastructure as Code |
| [Ansible](05-ansible.md) | Configuration management |

### CI/CD Platforms

| Document | Description |
|----------|-------------|
| [CI/CD Concepts](03-cicd.md) | Core principles |
| [Jenkins](07-jenkins.md) | Jenkins pipelines |
| [GitHub Actions](16-github-actions.md) | GitHub workflows |
| [GitLab CI](17-gitlab-ci.md) | GitLab pipelines |
| [CircleCI](18-circleci.md) | CircleCI configuration |

### Operations

| Document | Description |
|----------|-------------|
| [Monitoring](09-monitoring.md) | Observability and alerting |
| [GitOps](10-gitops.md) | Git-based operations |
| [Vault](11-vault.md) | Secrets management |
| [Databases](13-databases.md) | Database operations |

### Reference

| Document | Description |
|----------|-------------|
| [Security](14-security.md) | Security best practices |
| [Troubleshooting](15-troubleshooting.md) | Debugging guide |
| [Linux](03-linux.md) | Linux fundamentals |

## Getting Help

1. Check the [Troubleshooting Guide](15-troubleshooting.md)
2. Review example README files
3. Search documentation for specific topics

## Next Steps

Start with Docker basics in [04-docker.md](04-docker.md) if you're new to containers, or jump to [06-kubernetes.md](06-kubernetes.md) if you're ready for orchestration.

Happy learning! 🚀
