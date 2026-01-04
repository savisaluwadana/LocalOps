# Local DevOps Playground

A comprehensive local environment for learning and practicing DevOps tools: Linux, Docker, Ansible, Terraform, Jenkins, and Kubernetes.

## 🚀 Quick Start

```bash
# Install OrbStack (our unified platform)
brew install orbstack

# Install CLI tools
brew install terraform ansible kubectl helm

# Create your first Linux VM
orb create ubuntu:22.04 playground-vm
ssh playground-vm
```

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/00-getting-started.md) | Setup and first steps |
| [Architecture](docs/01-overview.md) | How everything fits together |
| [Prerequisites](docs/02-prerequisites.md) | Installation requirements |
| [Linux](docs/03-linux.md) | Filesystem, commands, scripting |
| [Docker](docs/04-docker.md) | Containers, images, Compose |
| [Ansible](docs/05-ansible.md) | Configuration management |
| [Terraform](docs/06-terraform.md) | Infrastructure as Code |
| [Jenkins](docs/07-jenkins.md) | CI/CD pipelines |
| [Kubernetes](docs/08-kubernetes.md) | Container orchestration |

## 🛠 Playground

Ready-to-use configurations in `playground/`:

```
playground/
├── orbstack/      # Linux VM instructions
├── terraform/     # Docker provisioning
├── ansible/       # Server configuration
├── jenkins/       # CI/CD server
└── kubernetes/    # K8s manifests
```

## 📋 Requirements

- **macOS** with Apple Silicon or Intel
- **OrbStack** (replaces Docker Desktop + VirtualBox)
- **8GB RAM** minimum (16GB recommended)
- **10GB disk space**

## 🎯 Learning Path

1. Start with **Linux basics** → Practice in OrbStack VM
2. Learn **Docker** → Build and run containers
3. Master **Ansible** → Configure your VMs automatically
4. Understand **Terraform** → Provision Docker resources as code
5. Set up **Jenkins** → Create your first CI/CD pipeline
6. Deploy to **Kubernetes** → Orchestrate containers at scale

## 📝 License

MIT