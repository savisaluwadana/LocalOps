# Infrastructure Automation with Terraform + Ansible

Complete infrastructure automation example combining Terraform for provisioning and Ansible for configuration.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  Terraform (Provision)          Ansible (Configure)                         │
│  ┌──────────────────┐          ┌──────────────────┐                         │
│  │                  │          │                  │                         │
│  │  Create Docker   │ ───────► │  Install apps    │                         │
│  │  containers      │          │  Configure nginx │                         │
│  │  Create networks │          │  Setup users     │                         │
│  │  Create volumes  │          │  Deploy code     │                         │
│  │                  │          │                  │                         │
│  └──────────────────┘          └──────────────────┘                         │
│                                                                              │
│  Output: IP addresses           Input: Terraform outputs                    │
│          Port mappings                  Dynamic inventory                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Provision infrastructure
cd terraform
terraform init
terraform apply

# 2. Configure with Ansible
cd ../ansible
ansible-playbook -i inventory.ini site.yml

# 3. Verify
curl http://localhost:8080
```

## What Gets Created

### By Terraform:
- 3 web server containers (nginx)
- 1 database container (PostgreSQL)
- 1 cache container (Redis)
- Docker network for communication
- Persistent volumes for data

### By Ansible:
- Custom nginx configuration
- Application deployment
- User management
- Security hardening
