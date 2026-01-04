# CI/CD Pipeline Example

Complete CI/CD setup demonstrating the full software delivery lifecycle.

## Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CI/CD PIPELINE                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐       │
│  │  Code   │──►│  Build  │──►│  Test   │──►│ Package │──►│ Deploy  │       │
│  │  Push   │   │         │   │         │   │         │   │         │       │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘       │
│       │             │             │             │             │             │
│       │        Compile       Unit Tests    Docker Image    K8s/Docker      │
│       │        Lint          Integration   Push Registry   Compose         │
│  Git webhook   Dependencies  E2E Tests     Tag & Version                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Start Jenkins
docker compose up -d

# Access Jenkins
open http://localhost:8080

# Get initial password
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Pipeline Features

1. **Parallel Testing** - Unit, integration, E2E tests run simultaneously
2. **Docker Build** - Multi-stage builds with caching
3. **Security Scanning** - Vulnerability checks before deploy
4. **Multi-Environment** - Dev, staging, prod deployments
5. **Rollback** - One-click rollback on failures

## Files

| File | Purpose |
|------|---------|
| `Jenkinsfile` | Main pipeline definition |
| `Jenkinsfile.parallel` | Parallel testing example |
| `Jenkinsfile.multibranch` | Branch-based deployments |
| `.github/workflows/ci.yml` | GitHub Actions alternative |
