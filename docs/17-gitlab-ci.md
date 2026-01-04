# GitLab CI/CD In-Depth Guide

## What is GitLab CI/CD?

GitLab CI/CD is an integrated DevOps platform for building, testing, and deploying code.

## Core Concepts

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GITLAB CI/CD ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Git Push / Merge Request                                                    │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    PIPELINE (.gitlab-ci.yml)                         │    │
│  │                                                                      │    │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │    │
│  │  │  STAGE 1   │→ │  STAGE 2   │→ │  STAGE 3   │→ │  STAGE 4   │    │    │
│  │  │   build    │  │    test    │  │   deploy   │  │  cleanup   │    │    │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘    │    │
│  │        │               │               │               │            │    │
│  │    ┌───┴───┐       ┌───┼───┐       ┌───┴───┐       ┌───┴───┐      │    │
│  │    │ build │       │unit│e2e│       │staging│       │cleanup│      │    │
│  │    │  job  │       │test│test│      │  job  │       │ job   │      │    │
│  │    └───────┘       └───┴───┘       └───────┘       └───────┘      │    │
│  │                                         │                          │    │
│  │                                    ┌────┴────┐                     │    │
│  │                                    │production│                     │    │
│  │                                    │   job   │  (manual)           │    │
│  │                                    └─────────┘                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         GITLAB RUNNERS                               │    │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │    │
│  │   │ Shared Runner│  │ Group Runner │  │Project Runner│             │    │
│  │   │  (GitLab.com)│  │  (your org)  │  │  (dedicated) │             │    │
│  │   └──────────────┘  └──────────────┘  └──────────────┘             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Terms

| Term | Description |
|------|-------------|
| **Pipeline** | Top-level component, collection of stages |
| **Stage** | Group of jobs that run in parallel |
| **Job** | Task that runs scripts |
| **Runner** | Agent that executes jobs |
| **Artifact** | File passed between jobs |
| **Cache** | Speeds up job execution |

---

## Complete Pipeline Example

```yaml
# .gitlab-ci.yml

# Variables available to all jobs
variables:
  DOCKER_REGISTRY: registry.gitlab.com
  IMAGE_NAME: $CI_REGISTRY_IMAGE
  KUBERNETES_NAMESPACE: myapp

# Stages define execution order
stages:
  - validate
  - build
  - test
  - security
  - deploy
  - cleanup

# Default settings for all jobs
default:
  image: node:18-alpine
  before_script:
    - echo "Pipeline $CI_PIPELINE_ID started"
  after_script:
    - echo "Job $CI_JOB_NAME completed"
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure

# Cache node_modules
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
  policy: pull-push

# ============================================
# VALIDATE STAGE
# ============================================
lint:
  stage: validate
  script:
    - npm ci
    - npm run lint
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

validate-yaml:
  stage: validate
  image: python:3.11
  script:
    - pip install yamllint
    - yamllint .
  allow_failure: true

# ============================================
# BUILD STAGE
# ============================================
build:
  stage: build
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  rules:
    - if: $CI_COMMIT_BRANCH

build-docker:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_NAME:$CI_COMMIT_SHA .
    - docker push $IMAGE_NAME:$CI_COMMIT_SHA
    - docker tag $IMAGE_NAME:$CI_COMMIT_SHA $IMAGE_NAME:latest
    - docker push $IMAGE_NAME:latest
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG

# ============================================
# TEST STAGE
# ============================================
unit-tests:
  stage: test
  script:
    - npm ci
    - npm test -- --coverage
  coverage: '/Lines\s*:\s*(\d+\.?\d*)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    paths:
      - coverage/
  needs:
    - build

integration-tests:
  stage: test
  services:
    - postgres:15
    - redis:alpine
  variables:
    POSTGRES_DB: test
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: postgres://test:test@postgres:5432/test
    REDIS_URL: redis://redis:6379
  script:
    - npm ci
    - npm run test:integration
  needs:
    - build

e2e-tests:
  stage: test
  image: cypress/included:latest
  script:
    - npm ci
    - npm run test:e2e
  artifacts:
    when: always
    paths:
      - cypress/screenshots/
      - cypress/videos/
  needs:
    - build
  allow_failure: true

# ============================================
# SECURITY STAGE
# ============================================
sast:
  stage: security
  image: 
    name: securego/gosec:latest
    entrypoint: [""]
  script:
    - echo "Running SAST..."
  artifacts:
    reports:
      sast: gl-sast-report.json

dependency-scan:
  stage: security
  script:
    - npm audit --audit-level=high
  allow_failure: true

container-scan:
  stage: security
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_NAME:$CI_COMMIT_SHA
  needs:
    - build-docker
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# ============================================
# DEPLOY STAGE
# ============================================
deploy-staging:
  stage: deploy
  image: bitnami/kubectl:latest
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop-staging
  script:
    - kubectl config set-cluster k8s --server=$KUBE_SERVER --certificate-authority=$KUBE_CA
    - kubectl config set-credentials gitlab --token=$KUBE_TOKEN
    - kubectl config set-context default --cluster=k8s --user=gitlab
    - kubectl config use-context default
    - kubectl set image deployment/app app=$IMAGE_NAME:$CI_COMMIT_SHA -n staging
    - kubectl rollout status deployment/app -n staging --timeout=5m
  needs:
    - build-docker
    - unit-tests
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

stop-staging:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl scale deployment/app --replicas=0 -n staging
  environment:
    name: staging
    action: stop
  when: manual
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy-production:
  stage: deploy
  image: bitnami/kubectl:latest
  environment:
    name: production
    url: https://example.com
  script:
    - kubectl set image deployment/app app=$IMAGE_NAME:$CI_COMMIT_SHA -n production
    - kubectl rollout status deployment/app -n production --timeout=10m
  needs:
    - build-docker
    - unit-tests
    - container-scan
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  when: manual

# ============================================
# CLEANUP STAGE
# ============================================
cleanup-images:
  stage: cleanup
  image: docker:24
  services:
    - docker:24-dind
  script:
    - 'docker images --filter "dangling=true" -q | xargs -r docker rmi || true'
  when: always
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

---

## Parent-Child Pipelines

### Parent Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - triggers

trigger-frontend:
  stage: triggers
  trigger:
    include: frontend/.gitlab-ci.yml
    strategy: depend
  rules:
    - changes:
        - frontend/**/*

trigger-backend:
  stage: triggers
  trigger:
    include: backend/.gitlab-ci.yml
    strategy: depend
  rules:
    - changes:
        - backend/**/*
```

### Child Pipeline

```yaml
# frontend/.gitlab-ci.yml
stages:
  - build
  - test

build:
  stage: build
  script:
    - cd frontend
    - npm ci
    - npm run build
```

---

## Environments and Deployments

```yaml
deploy-review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.example.com
    auto_stop_in: 1 week
    on_stop: stop-review
  script:
    - deploy-to-review.sh
  rules:
    - if: $CI_MERGE_REQUEST_IID

stop-review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  script:
    - teardown-review.sh
  when: manual
  rules:
    - if: $CI_MERGE_REQUEST_IID
```

---

## Templates and Includes

### Using Templates

```yaml
include:
  # Official templates
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  
  # Remote file
  - remote: 'https://example.com/templates/deploy.yml'
  
  # Local file
  - local: '/templates/common.yml'
  
  # From another project
  - project: 'group/project'
    ref: main
    file: '/templates/deploy.yml'
```

### Creating Templates

```yaml
# templates/node-test.yml
.node-test:
  image: node:18
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  before_script:
    - npm ci

# Using the template
test:
  extends: .node-test
  script:
    - npm test
```

---

## GitLab Runner Setup

### Install Runner

```bash
# Linux
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner

# Register
sudo gitlab-runner register \
  --url https://gitlab.com/ \
  --registration-token YOUR_TOKEN \
  --executor docker \
  --docker-image alpine:latest \
  --description "My Runner" \
  --tag-list "docker,linux"
```

### Runner Config

```toml
# /etc/gitlab-runner/config.toml
concurrent = 4
check_interval = 0

[[runners]]
  name = "Docker Runner"
  url = "https://gitlab.com/"
  token = "TOKEN"
  executor = "docker"
  [runners.docker]
    image = "alpine:latest"
    privileged = true
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
  [runners.cache]
    Type = "s3"
    Shared = true
```

---

## GitLab vs GitHub Actions

| Feature | GitLab CI | GitHub Actions |
|---------|-----------|----------------|
| Config file | `.gitlab-ci.yml` | `.github/workflows/*.yml` |
| Stages | Explicit stages | Jobs with `needs` |
| Variables | `variables:` | `env:` |
| Secrets | Settings → CI/CD | Settings → Secrets |
| Runners | GitLab Runners | Runners |
| Matrix | `parallel: matrix:` | `strategy: matrix:` |
| Artifacts | `artifacts:` | `actions/upload-artifact` |
| Cache | `cache:` | `actions/cache` |
