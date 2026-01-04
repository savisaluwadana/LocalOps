# Example Web Application

A complete example demonstrating how all DevOps tools work together.

## Quick Start

```bash
cd playground/examples/webapp

# Start the stack
docker compose up -d

# Access:
# - App: http://localhost:5000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000 (admin/admin)
```

## What's Included

- **Flask Application** with Prometheus metrics
- **PostgreSQL** database
- **Redis** cache
- **Prometheus** for metrics collection
- **Grafana** for visualization

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | App status |
| `GET /health` | Health check |
| `GET /ready` | Readiness check (includes DB) |
| `GET /metrics` | Prometheus metrics |
| `GET /users` | List users from DB |
| `GET /cache/<key>` | Get cached value |
| `POST /cache/<key>/<value>` | Set cached value |

## Integration Examples

### Deploy with Terraform

```bash
cd ../terraform
# Update main.tf to use this image
terraform apply
```

### Configure with Ansible

```bash
cd ../ansible
ansible-playbook -i inventory.ini deploy_webapp.yml
```

### Deploy to Kubernetes

```bash
cd ../kubernetes
kubectl apply -f webapp-deployment.yaml
```
