# GitLab CI/CD Complete Guide

## Table of Contents

1. [GitLab CI Fundamentals](#gitlab-ci-fundamentals)
2. [Pipeline Configuration](#pipeline-configuration)
3. [Jobs and Stages](#jobs-and-stages)
4. [Variables and Secrets](#variables-and-secrets)
5. [Runners](#runners)
6. [Caching and Artifacts](#caching-and-artifacts)
7. [Environments and Deployments](#environments-and-deployments)
8. [Advanced Patterns](#advanced-patterns)
9. [Best Practices](#best-practices)

---

## GitLab CI Fundamentals

### What is GitLab CI?

**GitLab CI/CD** is GitLab's built-in continuous integration and delivery platform. Pipelines are defined in `.gitlab-ci.yml` at the repository root.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Pipeline** | Top-level CI/CD workflow |
| **Stage** | Group of jobs that run together |
| **Job** | Individual task to execute |
| **Runner** | Agent that executes jobs |
| **Artifact** | Files passed between jobs |

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     GITLAB CI/CD FLOW                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐                                                       │
│   │    Commit    │  triggers pipeline                                   │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          ▼                                                               │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │                      PIPELINE                                 │      │
│   │                                                              │      │
│   │  Stage: build      Stage: test       Stage: deploy          │      │
│   │  ┌──────────┐     ┌──────────┐      ┌──────────┐           │      │
│   │  │  build   │ ──▶ │  test    │ ──▶  │  deploy  │           │      │
│   │  └──────────┘     │  lint    │      └──────────┘           │      │
│   │                   └──────────┘                              │      │
│   │                                                              │      │
│   └──────────────────────────────────────────────────────────────┘      │
│                              │                                           │
│                              ▼                                           │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │                       RUNNERS                                 │      │
│   │    Shared       Group        Project        Self-hosted      │      │
│   │    Runner       Runner       Runner         Runner           │      │
│   └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Pipeline Configuration

### Basic Structure

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  APP_NAME: my-app

build:
  stage: build
  image: node:20
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/

test:
  stage: test
  image: node:20
  script:
    - npm ci
    - npm test

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  only:
    - main
```

---

## Jobs and Stages

### Job Configuration

```yaml
my-job:
  stage: build
  image: alpine:latest
  
  # Before and after scripts
  before_script:
    - echo "Setting up..."
  
  script:
    - echo "Main commands"
    - ./build.sh
  
  after_script:
    - echo "Cleanup"
  
  # Conditions
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: always
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual

  # Tags to select runner
  tags:
    - docker
    - linux
  
  # Timeout
  timeout: 30 minutes
  
  # Retry on failure
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

### Parallel Jobs

```yaml
test:
  stage: test
  parallel: 4
  script:
    - npm test -- --shard=$CI_NODE_INDEX/$CI_NODE_TOTAL
```

### Job Dependencies

```yaml
stages:
  - build
  - test
  - deploy

build-frontend:
  stage: build
  script: npm run build:frontend
  artifacts:
    paths:
      - frontend/dist/

build-backend:
  stage: build
  script: npm run build:backend

test:
  stage: test
  needs:
    - build-frontend
    - build-backend
  script: npm test

deploy:
  stage: deploy
  needs:
    - job: test
      artifacts: true
  script: ./deploy.sh
```

---

## Variables and Secrets

### Variable Types

```yaml
variables:
  # Global variables
  APP_NAME: my-app
  BUILD_TYPE: production

job:
  variables:
    # Job-specific
    JOB_VAR: value
  script:
    - echo $APP_NAME
    - echo $CI_COMMIT_SHA  # Predefined
```

### Protected and Masked Variables

```yaml
# Set in GitLab UI (Settings → CI/CD → Variables)
# - Protected: only available on protected branches
# - Masked: hidden in logs

job:
  script:
    - docker login -u $REGISTRY_USER -p $REGISTRY_PASSWORD
    - ./deploy.sh --key=$DEPLOY_KEY
```

### Common Predefined Variables

| Variable | Description |
|----------|-------------|
| `CI_COMMIT_SHA` | Full commit SHA |
| `CI_COMMIT_SHORT_SHA` | First 8 chars of SHA |
| `CI_COMMIT_BRANCH` | Branch name |
| `CI_COMMIT_TAG` | Tag name |
| `CI_PIPELINE_ID` | Pipeline ID |
| `CI_JOB_ID` | Job ID |
| `CI_PROJECT_NAME` | Project name |
| `CI_PROJECT_DIR` | Checkout directory |

---

## Runners

### Runner Types

| Type | Description | Use Case |
|------|-------------|----------|
| Shared | Available to all projects | Default option |
| Group | Available to group projects | Team-wide tools |
| Project | Specific to one project | Special requirements |
| Self-hosted | Your own infrastructure | Security, performance |

### Docker Executor

```yaml
job:
  image: node:20
  services:
    - postgres:15
    - redis:7
  variables:
    POSTGRES_DB: test
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
  script:
    - npm test
```

### Kubernetes Executor

```yaml
# In runner config.toml
[[runners]]
  name = "kubernetes-runner"
  executor = "kubernetes"
  [runners.kubernetes]
    namespace = "gitlab-runner"
    [runners.kubernetes.pod_annotations]
      "vault.hashicorp.com/agent-inject": "true"
```

---

## Caching and Artifacts

### Caching Dependencies

```yaml
variables:
  npm_config_cache: "$CI_PROJECT_DIR/.npm"

cache:
  key:
    files:
      - package-lock.json
  paths:
    - .npm/
    - node_modules/

build:
  script:
    - npm ci --cache .npm
    - npm run build
```

### Artifacts

```yaml
build:
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura.xml
    expire_in: 1 week

test:
  needs:
    - job: build
      artifacts: true
  script:
    - ls dist/  # Artifact from build job
```

---

## Environments and Deployments

### Environment Configuration

```yaml
deploy-staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - ./deploy.sh staging
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  script:
    - ./deploy.sh production
  rules:
    - if: $CI_COMMIT_TAG
  when: manual
```

### Review Apps

```yaml
deploy-review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.example.com
    on_stop: stop-review
  script:
    - ./deploy-review.sh
  rules:
    - if: $CI_MERGE_REQUEST_IID

stop-review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  script:
    - ./stop-review.sh
  rules:
    - if: $CI_MERGE_REQUEST_IID
      when: manual
```

---

## Advanced Patterns

### Include and Extend

```yaml
# .gitlab-ci.yml
include:
  - local: '/templates/docker-build.yml'
  - template: Security/SAST.gitlab-ci.yml
  - project: 'my-group/my-project'
    file: '/templates/base.yml'
    ref: main

.base-job:
  image: node:20
  before_script:
    - npm ci

build:
  extends: .base-job
  script:
    - npm run build
```

### Parent-Child Pipelines

```yaml
# .gitlab-ci.yml
trigger-backend:
  trigger:
    include: backend/.gitlab-ci.yml
    strategy: depend

trigger-frontend:
  trigger:
    include: frontend/.gitlab-ci.yml
    strategy: depend
```

### Dynamic Pipelines

```yaml
generate-config:
  stage: .pre
  script:
    - ./generate-pipeline.sh > generated-config.yml
  artifacts:
    paths:
      - generated-config.yml

trigger-generated:
  stage: build
  trigger:
    include:
      - artifact: generated-config.yml
        job: generate-config
```

---

## Best Practices

### Performance

1. **Use caching** - Speed up dependency installation
2. **Parallelize** - Split test suites
3. **Use `needs`** - Define job dependencies explicitly
4. **Optimize images** - Use slim base images

### Security

1. **Use CI/CD variables** - Never hardcode secrets
2. **Protected branches** - Restrict who can deploy
3. **Masked variables** - Hide sensitive values
4. **Review `.gitlab-ci.yml`** - Audit pipeline changes

### Organization

```yaml
# Use anchors for reuse
.npm-job: &npm-job
  image: node:20
  cache:
    key: npm
    paths:
      - node_modules/

build:
  <<: *npm-job
  stage: build
  script:
    - npm run build

test:
  <<: *npm-job
  stage: test
  script:
    - npm test
```

### Pipeline Rules

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "web"
```

This guide covers GitLab CI/CD from fundamentals to advanced patterns for building robust deployment pipelines.
