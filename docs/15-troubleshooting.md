# Troubleshooting Guide

Common issues and solutions for your DevOps playground.

---

## OrbStack Issues

| Problem | Solution |
|---------|----------|
| OrbStack not starting | Restart from menu bar → Quit, then reopen |
| Docker commands fail | Check `orb status`, restart if needed |
| VM not accessible | `orb stop <vm> && orb start <vm>` |
| Kubernetes not working | Enable in OrbStack Preferences → Kubernetes |

```bash
# Reset OrbStack
orb stop
orb start

# Check status
orb status
```

---

## Docker Issues

### Container won't start

```bash
# Check logs
docker logs <container>

# Check resource usage
docker stats

# Remove and recreate
docker compose down
docker compose up -d
```

### Port already in use

```bash
# Find what's using the port
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### Out of disk space

```bash
# Clean up everything
docker system prune -a

# Remove unused volumes
docker volume prune
```

---

## Terraform Issues

### State lock

```bash
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

### Provider issues

```bash
# Clear and reinitialize
rm -rf .terraform
terraform init
```

### Dependency errors

```bash
# Refresh state
terraform refresh

# Target specific resource
terraform apply -target=docker_container.nginx
```

---

## Kubernetes Issues

### Pod stuck in Pending

```bash
# Check events
kubectl describe pod <pod-name>

# Common causes:
# - Insufficient resources
# - Node selector doesn't match
# - PVC not bound
```

### Pod stuck in CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name> --previous

# Common causes:
# - Application error
# - Missing config/secrets
# - Wrong command/args
```

### Service not accessible

```bash
# Check endpoints
kubectl get endpoints <service-name>

# Check selector matches pod labels
kubectl describe svc <service-name>
```

---

## Ansible Issues

### SSH connection failed

```bash
# Test SSH manually
ssh <hostname>

# Check inventory
ansible -i inventory.ini all -m ping -vvv
```

### Module not found

```bash
# Install collection
ansible-galaxy collection install community.general
```

---

## Jenkins Issues

### Can't access UI

```bash
# Check container logs
docker logs jenkins

# Verify port mapping
docker ps | grep jenkins
```

### Pipeline stuck

```bash
# Check executor status in Jenkins UI
# Restart Jenkins if needed
docker restart jenkins
```

---

## Quick Diagnostic Commands

```bash
# System resources
df -h          # Disk space
free -h        # Memory (Linux)
docker stats   # Container resources

# Network
netstat -tuln  # Open ports
curl -v URL    # Test HTTP
dig domain     # DNS lookup

# Process
ps aux | grep <name>
lsof -i :<port>
```
