# Troubleshooting Guide for DevOps

## Table of Contents

1. [Troubleshooting Methodology](#troubleshooting-methodology)
2. [Docker Troubleshooting](#docker-troubleshooting)
3. [Kubernetes Troubleshooting](#kubernetes-troubleshooting)
4. [Network Troubleshooting](#network-troubleshooting)
5. [Application Troubleshooting](#application-troubleshooting)
6. [CI/CD Troubleshooting](#cicd-troubleshooting)
7. [Common Issues Reference](#common-issues-reference)

---

## Troubleshooting Methodology

### The Scientific Method for Debugging

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    TROUBLESHOOTING WORKFLOW                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. OBSERVE                                                             │
│      • What's the symptom?                                              │
│      • When did it start?                                               │
│      • What changed?                                                    │
│                         ↓                                                │
│   2. REPRODUCE                                                           │
│      • Can you reliably reproduce it?                                   │
│      • What are the exact steps?                                        │
│                         ↓                                                │
│   3. HYPOTHESIZE                                                         │
│      • What could cause this?                                           │
│      • List possibilities                                               │
│                         ↓                                                │
│   4. TEST                                                                │
│      • Test ONE thing at a time                                         │
│      • Document what you tried                                          │
│                         ↓                                                │
│   5. FIX & VERIFY                                                        │
│      • Apply the fix                                                    │
│      • Confirm symptom is resolved                                      │
│                         ↓                                                │
│   6. DOCUMENT                                                            │
│      • What was the root cause?                                         │
│      • How can we prevent it?                                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Docker Troubleshooting

### Container Won't Start

```bash
# Check container status
docker ps -a

# View logs
docker logs <container_id>
docker logs --tail 100 -f <container_id>

# Inspect container
docker inspect <container_id>

# Check exit code
docker inspect <container_id> --format='{{.State.ExitCode}}'
```

### Common Exit Codes

| Code | Meaning | Common Cause |
|------|---------|--------------|
| 0 | Success | Normal exit |
| 1 | General error | Application error |
| 137 | SIGKILL | OOM killed |
| 139 | SIGSEGV | Segmentation fault |
| 143 | SIGTERM | Graceful shutdown |

### Image Issues

```bash
# Build with no cache
docker build --no-cache -t myapp .

# Check image layers
docker history myapp:latest

# Prune unused images
docker image prune -a

# Check disk usage
docker system df
```

### Network Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect <network>

# Test connectivity
docker run --rm --network <network> alpine ping <target>

# Check ports
docker port <container>
```

---

## Kubernetes Troubleshooting

### Pod Issues

```bash
# Pod status
kubectl get pods -o wide
kubectl describe pod <pod>

# Pod logs
kubectl logs <pod>
kubectl logs <pod> -c <container>  # Multi-container
kubectl logs <pod> --previous      # Previous crash

# Execute in pod
kubectl exec -it <pod> -- sh

# Check events
kubectl get events --sort-by=.lastTimestamp
```

### Pod States

| State | Meaning | Action |
|-------|---------|--------|
| Pending | Not scheduled | Check node resources, PVC |
| ImagePullBackOff | Can't pull image | Check image name, registry auth |
| CrashLoopBackOff | Crashing repeatedly | Check logs, resource limits |
| OOMKilled | Out of memory | Increase memory limit |
| Evicted | Node pressure | Check node resources |

### Debugging Commands

```bash
# Resource usage
kubectl top pod
kubectl top node

# Describe resource
kubectl describe <resource> <name>

# Get YAML
kubectl get <resource> <name> -o yaml

# Check endpoints
kubectl get endpoints

# DNS debugging
kubectl run debug --rm -it --image=busybox -- nslookup kubernetes
```

### Service Issues

```bash
# Check service
kubectl get svc
kubectl describe svc <service>

# Verify endpoints
kubectl get endpoints <service>

# Test service connectivity
kubectl run debug --rm -it --image=curlimages/curl -- curl http://<service>:<port>

# Check ingress
kubectl describe ingress <ingress>
```

---

## Network Troubleshooting

### DNS Issues

```bash
# Test DNS resolution
nslookup example.com
dig example.com

# Check DNS configuration
cat /etc/resolv.conf

# In Kubernetes
kubectl run debug --rm -it --image=busybox -- nslookup <service>
```

### Connectivity Issues

```bash
# Test port connectivity
nc -zv <host> <port>
telnet <host> <port>

# Trace route
traceroute <host>
mtr <host>

# Check listening ports
netstat -tlnp
ss -tlnp

# TCP dump
tcpdump -i eth0 port 80
```

### TLS/Certificate Issues

```bash
# Check certificate
openssl s_client -connect example.com:443 -servername example.com

# View certificate details
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -text

# Check certificate expiry
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
```

---

## Application Troubleshooting

### Performance Issues

```bash
# CPU/memory usage
top
htop

# Disk I/O
iostat -x 1
iotop

# Network statistics
netstat -s
ss -s

# Process info
ps aux | grep <process>
strace -p <pid>
```

### Log Analysis

```bash
# Search logs
grep "error" /var/log/app.log
grep -i "exception" /var/log/app.log | tail -100

# Count occurrences
grep -c "error" /var/log/app.log

# Context around matches
grep -B5 -A5 "error" /var/log/app.log

# Watch logs
tail -f /var/log/app.log | grep --line-buffered "error"
```

### Database Connection Issues

```bash
# Test PostgreSQL
psql -h <host> -U <user> -d <database> -c "SELECT 1"

# Test MongoDB
mongosh --host <host> --eval "db.adminCommand('ping')"

# Test Redis
redis-cli -h <host> ping
```

---

## CI/CD Troubleshooting

### Pipeline Failures

| Issue | Check |
|-------|-------|
| Build fails | Dependencies, syntax errors |
| Tests fail | Test logs, environment differences |
| Deploy fails | Permissions, resource limits |
| Timeout | Resource constraints, network |

### Common Fixes

```yaml
# Cache dependencies
- name: Cache node modules
  uses: actions/cache@v3
  with:
    path: node_modules
    key: ${{ hashFiles('package-lock.json') }}

# Increase timeout
- name: Long running step
  run: ./long-script.sh
  timeout-minutes: 30

# Retry on failure
- name: Flaky step
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 5
    max_attempts: 3
    command: ./flaky-script.sh
```

---

## Common Issues Reference

### Quick Reference

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| Container OOMKilled | Memory limit too low | Increase memory limit |
| ImagePullBackOff | Wrong image name or auth | Check image path, credentials |
| CrashLoopBackOff | App crashes at startup | Check logs, health checks |
| Connection refused | Service not running | Check service, endpoints |
| DNS not resolving | CoreDNS issues | Restart CoreDNS, check configmap |
| Slow responses | Resource constraints | Scale up, optimize code |
| 502 Bad Gateway | Backend unavailable | Check backend health |
| 503 Service Unavailable | Overloaded | Scale up, add rate limiting |

### Emergency Commands

```bash
# Kill all containers
docker stop $(docker ps -q)

# Force delete stuck namespace
kubectl delete ns <namespace> --grace-period=0 --force

# Restart all pods in deployment
kubectl rollout restart deployment/<name>

# Evict pod from node
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Emergency scale down
kubectl scale deployment --all --replicas=0 -n <namespace>
```

This guide provides a systematic approach to troubleshooting common DevOps issues with practical commands and solutions.
