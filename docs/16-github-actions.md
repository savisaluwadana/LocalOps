# GitHub Actions Complete Guide

## Table of Contents

1. [GitHub Actions Fundamentals](#github-actions-fundamentals)
2. [Workflow Syntax](#workflow-syntax)
3. [Events and Triggers](#events-and-triggers)
4. [Jobs and Steps](#jobs-and-steps)
5. [Actions](#actions)
6. [Secrets and Variables](#secrets-and-variables)
7. [Matrix Builds](#matrix-builds)
8. [Reusable Workflows](#reusable-workflows)
9. [Best Practices](#best-practices)

---

## GitHub Actions Fundamentals

### What is GitHub Actions?

**GitHub Actions** is GitHub's built-in CI/CD platform that allows you to automate workflows directly in your repository.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Workflow** | Automated process defined in YAML |
| **Event** | Trigger that starts a workflow |
| **Job** | Set of steps that run on same runner |
| **Step** | Individual task in a job |
| **Action** | Reusable unit of code |
| **Runner** | Server that runs workflows |

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     GITHUB ACTIONS FLOW                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐                                                       │
│   │   Event      │  (push, PR, schedule, manual)                        │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          ▼                                                               │
│   ┌──────────────┐                                                       │
│   │   Workflow   │  (.github/workflows/*.yml)                           │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          ▼                                                               │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                          JOBS                                   │    │
│   │                                                                  │    │
│   │   ┌──────────┐  ┌──────────┐  ┌──────────┐                     │    │
│   │   │  Job 1   │  │  Job 2   │  │  Job 3   │                     │    │
│   │   │ (Linux)  │  │(Windows) │  │ (macOS)  │                     │    │
│   │   │          │  │          │  │          │                     │    │
│   │   │ Step 1   │  │ Step 1   │  │ Step 1   │                     │    │
│   │   │ Step 2   │  │ Step 2   │  │ Step 2   │                     │    │
│   │   │ Step 3   │  │          │  │          │                     │    │
│   │   └──────────┘  └──────────┘  └──────────┘                     │    │
│   │                                                                  │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Workflow Syntax

### Basic Structure

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Build
        run: npm run build
```

---

## Events and Triggers

### Common Events

```yaml
on:
  # Push to specific branches
  push:
    branches: [main, develop]
    paths:
      - 'src/**'
      - '!src/**/*.md'
  
  # Pull request events
  pull_request:
    types: [opened, synchronize, reopened]
  
  # Scheduled (cron)
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  
  # Manual trigger
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
  
  # On release
  release:
    types: [published]
  
  # From another workflow
  workflow_call:
```

---

## Jobs and Steps

### Job Configuration

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    
    # Timeout
    timeout-minutes: 30
    
    # Environment
    environment: production
    
    # Permissions
    permissions:
      contents: read
      packages: write
    
    # Outputs for other jobs
    outputs:
      version: ${{ steps.version.outputs.value }}
    
    steps:
      - uses: actions/checkout@v4
      
      - id: version
        run: echo "value=$(cat VERSION)" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
      - run: echo "Deploying version ${{ needs.build.outputs.version }}"
```

### Conditional Execution

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    
    steps:
      - name: Deploy to staging
        if: github.event_name == 'push'
        run: ./deploy-staging.sh
      
      - name: Deploy to production
        if: github.event.inputs.environment == 'production'
        run: ./deploy-prod.sh
      
      - name: Always run cleanup
        if: always()
        run: ./cleanup.sh
      
      - name: Run on failure
        if: failure()
        run: ./notify-failure.sh
```

---

## Actions

### Using Actions

```yaml
steps:
  # Official action
  - uses: actions/checkout@v4
  
  # With inputs
  - uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'
  
  # Third-party action
  - uses: docker/build-push-action@v5
    with:
      push: true
      tags: myapp:latest
```

### Creating a Custom Action

```yaml
# .github/actions/my-action/action.yml
name: 'My Custom Action'
description: 'Does something useful'

inputs:
  name:
    description: 'Name to greet'
    required: true
    default: 'World'

outputs:
  greeting:
    description: 'The greeting'

runs:
  using: 'composite'
  steps:
    - run: echo "Hello, ${{ inputs.name }}!"
      shell: bash
    
    - id: greeting
      run: echo "greeting=Hello, ${{ inputs.name }}" >> $GITHUB_OUTPUT
      shell: bash
```

---

## Secrets and Variables

### Using Secrets

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Deploy
        env:
          API_KEY: ${{ secrets.API_KEY }}
        run: ./deploy.sh
      
      - name: Docker login
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
```

### Environment Variables

```yaml
env:
  # Workflow-level
  APP_NAME: my-app

jobs:
  build:
    runs-on: ubuntu-latest
    
    env:
      # Job-level
      NODE_ENV: production
    
    steps:
      - name: Build
        env:
          # Step-level
          BUILD_VERSION: ${{ github.sha }}
        run: |
          echo "Building $APP_NAME"
          echo "Version: $BUILD_VERSION"
```

---

## Matrix Builds

### Basic Matrix

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [18, 20]
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      
      - run: npm test
```

### Advanced Matrix

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            node: 20
            experimental: false
          - os: ubuntu-latest
            node: 21
            experimental: true
        exclude:
          - os: windows-latest
            node: 18
    
    continue-on-error: ${{ matrix.experimental }}
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

---

## Reusable Workflows

### Creating a Reusable Workflow

```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy_key:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy
        env:
          DEPLOY_KEY: ${{ secrets.deploy_key }}
        run: ./deploy.sh ${{ inputs.environment }}
```

### Calling Reusable Workflow

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build
  
  deploy-staging:
    needs: build
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
    secrets:
      deploy_key: ${{ secrets.STAGING_DEPLOY_KEY }}
  
  deploy-production:
    needs: deploy-staging
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: production
    secrets:
      deploy_key: ${{ secrets.PROD_DEPLOY_KEY }}
```

---

## Best Practices

### Security

1. **Pin action versions** - Use SHA, not tags
2. **Minimal permissions** - Grant least privilege
3. **Avoid secrets in logs** - Use masking
4. **Audit third-party actions** - Review before using

```yaml
permissions:
  contents: read  # Minimal permissions

steps:
  - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
```

### Performance

1. **Cache dependencies** - Faster builds
2. **Parallelize jobs** - Run independent jobs concurrently
3. **Use matrix wisely** - Balance coverage vs time
4. **Cancel redundant** - Stop old runs

```yaml
jobs:
  build:
    steps:
      - uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Organization

1. **Meaningful names** - Describe what step does
2. **Split into jobs** - Logical groupings
3. **Use reusable workflows** - DRY principle
4. **Document workflows** - Comments and README

This guide covers GitHub Actions from fundamentals to advanced patterns for building robust CI/CD workflows.
