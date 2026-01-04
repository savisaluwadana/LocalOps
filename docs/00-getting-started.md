# Getting Started

Welcome to the Local DevOps Playground! This guide walks you through setting up and using the entire environment.

## Quick Setup (5 minutes)

### 1. Install OrbStack
```bash
brew install orbstack
# Open OrbStack and complete initial setup
# Enable Kubernetes in preferences
```

### 2. Install CLI Tools
```bash
brew install terraform ansible kubectl helm
```

### 3. Verify Installation
```bash
orb version
docker version
kubectl version --client
terraform version
ansible --version
```

---

## Your First Lab

### Step 1: Create a Linux VM
```bash
orb create ubuntu:22.04 playground-vm
ssh playground-vm
# You're now in a full Ubuntu environment!
exit
```

### Step 2: Deploy Infrastructure with Terraform
```bash
cd ~/LocalOps/playground/terraform
terraform init
terraform apply -auto-approve
# Visit http://localhost:8000
terraform destroy -auto-approve
```

### Step 3: Configure with Ansible
```bash
cd ~/LocalOps/playground/ansible
# Create inventory
echo "playground-vm" > inventory.ini
# Run playbook
ansible-playbook -i inventory.ini setup.yml
```

### Step 4: Deploy to Kubernetes
```bash
kubectl create deployment nginx --image=nginx:alpine
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc
```

---

## Learning Path

1. **Linux** → `docs/03-linux.md`
2. **Docker** → `docs/04-docker.md`
3. **Ansible** → `docs/05-ansible.md`
4. **Terraform** → `docs/06-terraform.md`
5. **Jenkins** → `docs/07-jenkins.md`
6. **Kubernetes** → `docs/08-kubernetes.md`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| OrbStack not responding | Restart OrbStack from menu bar |
| Docker daemon not running | `orb start` or open OrbStack app |
| Kubernetes not working | Enable K8s in OrbStack preferences |
| Ansible SSH fails | Check `ssh playground-vm` works first |
