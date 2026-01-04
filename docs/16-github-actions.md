# GitHub Actions In-Depth Guide

## What is GitHub Actions?

GitHub Actions is a CI/CD platform built into GitHub. It automates workflows triggered by events like pushes, pull requests, or schedules.

## Core Concepts

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GITHUB ACTIONS ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Event (push, PR, schedule)                                                  │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        WORKFLOW (.yml file)                          │    │
│  │  ┌───────────────────────────────────────────────────────────────┐  │    │
│  │  │                          JOB 1: build                          │  │    │
│  │  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                       │  │    │
│  │  │  │Step 1│→ │Step 2│→ │Step 3│→ │Step 4│  (runs on: ubuntu)    │  │    │
│  │  │  │Checkout│ │Setup │ │Build │ │Test  │                       │  │    │
│  │  │  └──────┘  └──────┘  └──────┘  └──────┘                       │  │    │
│  │  └───────────────────────────────────────────────────────────────┘  │    │
│  │                              │                                       │    │
│  │                              │ needs: build                          │    │
│  │                              ▼                                       │    │
│  │  ┌───────────────────────────────────────────────────────────────┐  │    │
│  │  │                          JOB 2: deploy                         │  │    │
│  │  │  ┌──────┐  ┌──────┐                                           │  │    │
│  │  │  │Step 1│→ │Step 2│  (runs-on: ubuntu, environment: prod)     │  │    │
│  │  │  │Login │  │Deploy│                                           │  │    │
│  │  │  └──────┘  └──────┘                                           │  │    │
│  │  └───────────────────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Terminology

| Term | Description |
|------|-------------|
| **Workflow** | Automated process defined in YAML |
| **Event** | Trigger (push, PR, schedule, manual) |
| **Job** | Set of steps running on same runner |
| **Step** | Individual task (action or script) |
| **Action** | Reusable unit of code |
| **Runner** | VM that executes jobs |

---

## Workflow Syntax Deep Dive

### Complete Workflow Example

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

# Triggers
on:
  push:
    branches: [main, develop]
    paths:
      - 'src/**'
      - 'package.json'
      - '.github/workflows/**'
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:  # Manual trigger
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

# Environment variables for all jobs
env:
  NODE_VERSION: '18'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# Concurrency control
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Permissions
permissions:
  contents: read
  packages: write
  pull-requests: write

jobs:
  # ============================================
  # JOB 1: Code Quality
  # ============================================
  lint:
    name: Lint & Format
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Check formatting
        run: npm run format:check

  # ============================================
  # JOB 2: Unit Tests
  # ============================================
  test:
    name: Unit Tests
    runs-on: ubuntu-latest
    needs: lint
    
    strategy:
      matrix:
        node-version: [16, 18, 20]
        os: [ubuntu-latest, macos-latest]
      fail-fast: false
    
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          fail_ci_if_error: true

  # ============================================
  # JOB 3: Security Scanning
  # ============================================
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

      - name: Run npm audit
        run: npm audit --audit-level=high

  # ============================================
  # JOB 4: Build Docker Image
  # ============================================
  build:
    name: Build & Push
    runs-on: ubuntu-latest
    needs: [test, security]
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
    
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix=
            type=semver,pattern={{version}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            VERSION=${{ github.sha }}
            BUILD_DATE=${{ github.event.head_commit.timestamp }}

  # ============================================
  # JOB 5: Deploy to Staging
  # ============================================
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.example.com
    
    steps:
      - uses: actions/checkout@v4

      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBE_CONFIG_STAGING }}

      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/app app=${{ needs.build.outputs.image_tag }} -n staging
          kubectl rollout status deployment/app -n staging --timeout=5m

      - name: Run smoke tests
        run: |
          sleep 30
          curl -f https://staging.example.com/health

  # ============================================
  # JOB 6: Deploy to Production
  # ============================================
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://example.com
    
    steps:
      - uses: actions/checkout@v4

      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBE_CONFIG_PRODUCTION }}

      - name: Blue-Green Deploy
        run: |
          # Deploy to green
          kubectl apply -f k8s/production/ -n production
          kubectl set image deployment/app-green app=${{ needs.build.outputs.image_tag }} -n production
          kubectl rollout status deployment/app-green -n production --timeout=10m
          
          # Switch traffic
          kubectl patch service app -p '{"spec":{"selector":{"version":"green"}}}' -n production

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployed to production: ${{ github.sha }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}

  # ============================================
  # JOB 7: Cleanup
  # ============================================
  cleanup:
    name: Cleanup old images
    runs-on: ubuntu-latest
    needs: [deploy-staging, deploy-production]
    if: always()
    
    steps:
      - name: Delete old container images
        uses: actions/delete-package-versions@v4
        with:
          package-name: ${{ env.IMAGE_NAME }}
          package-type: container
          min-versions-to-keep: 10
```

---

## Reusable Workflows

### Defining a Reusable Workflow

```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      image_tag:
        required: true
        type: string
    secrets:
      KUBE_CONFIG:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy
        run: |
          echo "Deploying ${{ inputs.image_tag }} to ${{ inputs.environment }}"
```

### Calling a Reusable Workflow

```yaml
# .github/workflows/main.yml
jobs:
  deploy:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: production
      image_tag: myapp:v1.2.3
    secrets:
      KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
```

---

## Composite Actions

### Creating a Custom Action

```yaml
# .github/actions/setup-and-test/action.yml
name: 'Setup and Test'
description: 'Setup Node.js and run tests'

inputs:
  node-version:
    description: 'Node.js version'
    required: false
    default: '18'

outputs:
  coverage:
    description: 'Coverage percentage'
    value: ${{ steps.test.outputs.coverage }}

runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    
    - name: Install
      shell: bash
      run: npm ci
    
    - name: Test
      id: test
      shell: bash
      run: |
        npm test -- --coverage
        echo "coverage=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')" >> $GITHUB_OUTPUT
```

### Using Custom Action

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-and-test
        with:
          node-version: '20'
```

---

## Matrix Strategies

```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [16, 18, 20]
        include:
          - os: ubuntu-latest
            node: 20
            experimental: true
        exclude:
          - os: windows-latest
            node: 16
      fail-fast: false
      max-parallel: 3
    
    runs-on: ${{ matrix.os }}
    continue-on-error: ${{ matrix.experimental || false }}
    
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

---

## Secrets and Environment Variables

```yaml
env:
  # Available to all jobs
  GLOBAL_VAR: 'value'

jobs:
  build:
    env:
      # Available to all steps in this job
      JOB_VAR: 'value'
    
    steps:
      - name: Use secrets
        env:
          # Step-level
          API_KEY: ${{ secrets.API_KEY }}
          # GitHub context
          REPO: ${{ github.repository }}
          SHA: ${{ github.sha }}
          REF: ${{ github.ref_name }}
        run: |
          echo "Repository: $REPO"
          echo "Commit: $SHA"
```

---

## Caching

```yaml
steps:
  - name: Cache npm dependencies
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-node-

  - name: Cache Docker layers
    uses: actions/cache@v3
    with:
      path: /tmp/.buildx-cache
      key: ${{ runner.os }}-buildx-${{ github.sha }}
      restore-keys: |
        ${{ runner.os }}-buildx-
```

---

## Self-Hosted Runners

```yaml
jobs:
  build:
    runs-on: self-hosted
    # Or with labels
    runs-on: [self-hosted, linux, x64, gpu]
```

### Setup Script

```bash
# Download runner
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64.tar.gz

# Configure
./config.sh --url https://github.com/OWNER/REPO --token TOKEN

# Run as service
sudo ./svc.sh install
sudo ./svc.sh start
```
