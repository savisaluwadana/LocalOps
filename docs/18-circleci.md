# CircleCI In-Depth Guide

## What is CircleCI?

CircleCI is a cloud-native CI/CD platform that automates the build, test, and deployment of software. It's known for its speed, flexibility, and powerful caching mechanisms.

## Core Concepts

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CIRCLECI ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Git Push / PR                                                               │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      PIPELINE (.circleci/config.yml)                 │    │
│  │                                                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │                      WORKFLOW: build-test-deploy             │    │    │
│  │  │                                                              │    │    │
│  │  │  ┌────────────┐                                              │    │    │
│  │  │  │  JOB 1     │                                              │    │    │
│  │  │  │   build    │                                              │    │    │
│  │  │  └─────┬──────┘                                              │    │    │
│  │  │        │                                                     │    │    │
│  │  │        ├─────────────────┐                                   │    │    │
│  │  │        │                 │                                   │    │    │
│  │  │        ▼                 ▼                                   │    │    │
│  │  │  ┌────────────┐   ┌────────────┐                            │    │    │
│  │  │  │  JOB 2     │   │  JOB 3     │  (parallel)                │    │    │
│  │  │  │ unit-test  │   │  lint      │                            │    │    │
│  │  │  └─────┬──────┘   └─────┬──────┘                            │    │    │
│  │  │        │                 │                                   │    │    │
│  │  │        └────────┬────────┘                                   │    │    │
│  │  │                 ▼                                            │    │    │
│  │  │           ┌────────────┐                                     │    │    │
│  │  │           │  JOB 4     │                                     │    │    │
│  │  │           │  deploy    │  (requires: test, lint)            │    │    │
│  │  │           └────────────┘                                     │    │    │
│  │  └──────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         EXECUTORS                                    │    │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │    │
│  │   │    Docker    │  │   Machine    │  │    macOS     │             │    │
│  │   │  (container) │  │    (VM)      │  │  (iOS/macOS) │             │    │
│  │   └──────────────┘  └──────────────┘  └──────────────┘             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Terms

| Term | Description |
|------|-------------|
| **Pipeline** | Collection of workflows triggered by an event |
| **Workflow** | Set of rules for running jobs |
| **Job** | Collection of steps run on an executor |
| **Step** | Executable command or orb action |
| **Executor** | Environment where job runs (docker, machine, macos) |
| **Orb** | Reusable package of configuration |

---

## Complete Configuration Example

```yaml
# .circleci/config.yml
version: 2.1

# ============================================
# ORBS - Reusable packages
# ============================================
orbs:
  node: circleci/node@5.1.0
  docker: circleci/docker@2.4.0
  kubernetes: circleci/kubernetes@1.3.1
  slack: circleci/slack@4.12.5

# ============================================
# PARAMETERS - Pipeline-level variables
# ============================================
parameters:
  run-integration-tests:
    type: boolean
    default: true
  target-environment:
    type: enum
    enum: [development, staging, production]
    default: development

# ============================================
# EXECUTORS - Reusable execution environments
# ============================================
executors:
  node-executor:
    docker:
      - image: cimg/node:18.18.0
    working_directory: ~/app
    resource_class: medium
    environment:
      NODE_ENV: test

  node-with-services:
    docker:
      - image: cimg/node:18.18.0
      - image: cimg/postgres:15.0
        environment:
          POSTGRES_USER: test
          POSTGRES_DB: testdb
          POSTGRES_PASSWORD: test
      - image: cimg/redis:7.0
    working_directory: ~/app

  machine-executor:
    machine:
      image: ubuntu-2204:2023.10.1
    resource_class: medium

# ============================================
# COMMANDS - Reusable step sequences
# ============================================
commands:
  setup-dependencies:
    description: "Install and cache dependencies"
    steps:
      - checkout
      - restore_cache:
          keys:
            - deps-v1-{{ checksum "package-lock.json" }}
            - deps-v1-
      - run:
          name: Install dependencies
          command: npm ci
      - save_cache:
          key: deps-v1-{{ checksum "package-lock.json" }}
          paths:
            - node_modules

  run-tests:
    description: "Run test suite with coverage"
    parameters:
      test-type:
        type: string
        default: "unit"
    steps:
      - run:
          name: Run << parameters.test-type >> tests
          command: npm run test:<< parameters.test-type >> -- --coverage
      - store_test_results:
          path: test-results
      - store_artifacts:
          path: coverage
          destination: coverage-<< parameters.test-type >>

  notify-slack:
    description: "Send Slack notification"
    parameters:
      status:
        type: string
    steps:
      - slack/notify:
          event: << parameters.status >>
          template: basic_success_1

# ============================================
# JOBS
# ============================================
jobs:
  # ---------- BUILD ----------
  build:
    executor: node-executor
    steps:
      - setup-dependencies
      - run:
          name: Build application
          command: npm run build
      - persist_to_workspace:
          root: .
          paths:
            - dist
            - node_modules
            - package.json

  # ---------- LINT ----------
  lint:
    executor: node-executor
    steps:
      - setup-dependencies
      - run:
          name: Run ESLint
          command: npm run lint -- --format junit --output-file test-results/eslint.xml
      - store_test_results:
          path: test-results

  # ---------- UNIT TESTS ----------
  unit-test:
    executor: node-executor
    parallelism: 4
    steps:
      - setup-dependencies
      - run:
          name: Split and run tests
          command: |
            TESTS=$(circleci tests glob "src/**/*.test.ts" | circleci tests split --split-by=timings)
            npm test -- $TESTS
      - store_test_results:
          path: test-results
      - store_artifacts:
          path: coverage

  # ---------- INTEGRATION TESTS ----------
  integration-test:
    executor: node-with-services
    steps:
      - setup-dependencies
      - run:
          name: Wait for services
          command: |
            dockerize -wait tcp://localhost:5432 -timeout 60s
            dockerize -wait tcp://localhost:6379 -timeout 60s
      - run:
          name: Run migrations
          command: npm run db:migrate
      - run-tests:
          test-type: integration

  # ---------- SECURITY SCAN ----------
  security-scan:
    executor: node-executor
    steps:
      - setup-dependencies
      - run:
          name: Run npm audit
          command: npm audit --audit-level=high
      - run:
          name: Run Snyk scan
          command: |
            npm install -g snyk
            snyk test || true
      - store_artifacts:
          path: security-report

  # ---------- BUILD DOCKER IMAGE ----------
  build-docker:
    executor: machine-executor
    steps:
      - checkout
      - attach_workspace:
          at: .
      - run:
          name: Build Docker image
          command: |
            docker build \
              --build-arg VERSION=${CIRCLE_SHA1} \
              --build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
              -t myapp:${CIRCLE_SHA1} \
              -t myapp:latest .
      - run:
          name: Save Docker image
          command: |
            mkdir -p docker-cache
            docker save myapp:${CIRCLE_SHA1} | gzip > docker-cache/image.tar.gz
      - persist_to_workspace:
          root: .
          paths:
            - docker-cache

  # ---------- PUSH DOCKER IMAGE ----------
  push-docker:
    executor: machine-executor
    steps:
      - attach_workspace:
          at: .
      - run:
          name: Load Docker image
          command: gunzip -c docker-cache/image.tar.gz | docker load
      - run:
          name: Push to registry
          command: |
            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
            docker tag myapp:${CIRCLE_SHA1} $DOCKER_REGISTRY/myapp:${CIRCLE_SHA1}
            docker tag myapp:${CIRCLE_SHA1} $DOCKER_REGISTRY/myapp:latest
            docker push $DOCKER_REGISTRY/myapp:${CIRCLE_SHA1}
            docker push $DOCKER_REGISTRY/myapp:latest

  # ---------- DEPLOY STAGING ----------
  deploy-staging:
    executor: node-executor
    steps:
      - checkout
      - kubernetes/install-kubectl
      - run:
          name: Configure kubectl
          command: |
            echo $KUBE_CONFIG_STAGING | base64 -d > kubeconfig
            export KUBECONFIG=./kubeconfig
      - run:
          name: Deploy to staging
          command: |
            kubectl set image deployment/myapp myapp=$DOCKER_REGISTRY/myapp:${CIRCLE_SHA1} -n staging
            kubectl rollout status deployment/myapp -n staging --timeout=5m
      - run:
          name: Run smoke tests
          command: |
            sleep 30
            curl -f https://staging.example.com/health

  # ---------- DEPLOY PRODUCTION ----------
  deploy-production:
    executor: node-executor
    steps:
      - checkout
      - kubernetes/install-kubectl
      - run:
          name: Deploy to production
          command: |
            echo $KUBE_CONFIG_PRODUCTION | base64 -d > kubeconfig
            export KUBECONFIG=./kubeconfig
            kubectl set image deployment/myapp myapp=$DOCKER_REGISTRY/myapp:${CIRCLE_SHA1} -n production
            kubectl rollout status deployment/myapp -n production --timeout=10m
      - notify-slack:
          status: pass

# ============================================
# WORKFLOWS
# ============================================
workflows:
  version: 2

  # Main CI/CD workflow
  build-test-deploy:
    jobs:
      # Build job
      - build:
          filters:
            branches:
              ignore: /dependabot.*/

      # Quality gates (parallel)
      - lint:
          requires:
            - build
      - unit-test:
          requires:
            - build
      - security-scan:
          requires:
            - build

      # Integration tests (conditional)
      - integration-test:
          requires:
            - unit-test
          filters:
            branches:
              only:
                - main
                - develop

      # Build Docker image
      - build-docker:
          requires:
            - lint
            - unit-test
            - security-scan
          filters:
            branches:
              only:
                - main
                - develop

      # Push Docker image
      - push-docker:
          requires:
            - build-docker
          context: docker-credentials

      # Deploy to staging
      - deploy-staging:
          requires:
            - push-docker
            - integration-test
          filters:
            branches:
              only: develop
          context: kubernetes-staging

      # Manual approval for production
      - hold-for-approval:
          type: approval
          requires:
            - push-docker
            - integration-test
          filters:
            branches:
              only: main

      # Deploy to production
      - deploy-production:
          requires:
            - hold-for-approval
          filters:
            branches:
              only: main
          context: kubernetes-production

  # Nightly builds
  nightly:
    triggers:
      - schedule:
          cron: "0 0 * * *"
          filters:
            branches:
              only: main
    jobs:
      - build
      - integration-test:
          requires:
            - build
      - security-scan:
          requires:
            - build
```

---

## Orbs Deep Dive

### What are Orbs?

Orbs are reusable, shareable packages of CircleCI configuration. They encapsulate jobs, commands, and executors.

### Popular Orbs

| Orb | Purpose |
|-----|---------|
| `circleci/node` | Node.js setup and caching |
| `circleci/docker` | Docker build and push |
| `circleci/kubernetes` | K8s deployment |
| `circleci/aws-ecr` | AWS ECR integration |
| `circleci/slack` | Slack notifications |
| `circleci/terraform` | Terraform commands |

### Using Orbs

```yaml
version: 2.1

orbs:
  node: circleci/node@5.1.0
  docker: circleci/docker@2.4.0

jobs:
  build:
    executor: node/default
    steps:
      - checkout
      - node/install-packages  # From orb
      - run: npm run build

  publish:
    executor: docker/docker
    steps:
      - setup_remote_docker
      - docker/check  # Login to Docker Hub
      - docker/build:
          image: myorg/myapp
          tag: ${CIRCLE_SHA1}
      - docker/push:
          image: myorg/myapp
          tag: ${CIRCLE_SHA1}
```

### Creating Custom Orbs

```yaml
# orbs/my-orb/orb.yml
version: 2.1

description: My custom orb

executors:
  default:
    docker:
      - image: cimg/base:current

commands:
  greet:
    parameters:
      name:
        type: string
        default: "World"
    steps:
      - run: echo "Hello, << parameters.name >>!"

jobs:
  hello-job:
    executor: default
    steps:
      - greet:
          name: "CircleCI"
```

---

## Caching Strategies

### Dependency Caching

```yaml
jobs:
  build:
    steps:
      - checkout
      
      # Restore cache
      - restore_cache:
          keys:
            - v1-deps-{{ checksum "package-lock.json" }}
            - v1-deps-{{ .Branch }}
            - v1-deps-
      
      - run: npm ci
      
      # Save cache
      - save_cache:
          key: v1-deps-{{ checksum "package-lock.json" }}
          paths:
            - node_modules
            - ~/.npm
```

### Docker Layer Caching (DLC)

```yaml
jobs:
  build-image:
    machine:
      docker_layer_caching: true  # Requires paid plan
    steps:
      - checkout
      - run: docker build -t myapp .
```

---

## Parallelism and Test Splitting

```yaml
jobs:
  test:
    parallelism: 4  # Run on 4 containers
    steps:
      - checkout
      - run:
          name: Run tests in parallel
          command: |
            # Glob all test files
            TESTFILES=$(circleci tests glob "**/*.test.js")
            
            # Split by timing data
            TESTFILES=$(echo $TESTFILES | circleci tests split --split-by=timings)
            
            # Run assigned tests
            npm test -- $TESTFILES
      
      - store_test_results:
          path: test-results
```

---

## Workspaces vs Caching

| Feature | Workspace | Cache |
|---------|-----------|-------|
| **Purpose** | Pass data between jobs in same workflow | Speed up future builds |
| **Lifetime** | Duration of workflow | Up to 15 days |
| **Use case** | Build artifacts, compiled code | Dependencies, node_modules |

### Workspace Example

```yaml
jobs:
  build:
    steps:
      - run: npm run build
      - persist_to_workspace:
          root: .
          paths:
            - dist

  deploy:
    steps:
      - attach_workspace:
          at: .
      - run: ls dist  # Built files available
```

---

## Contexts and Secrets

### Creating Contexts (UI)

1. Go to Organization Settings → Contexts
2. Create context (e.g., `aws-production`)
3. Add environment variables

### Using Contexts

```yaml
workflows:
  deploy:
    jobs:
      - deploy-prod:
          context:
            - aws-production
            - slack-notifications
```

---

## Matrix Jobs

```yaml
jobs:
  test:
    parameters:
      node-version:
        type: string
      os:
        type: executor
    executor: << parameters.os >>
    steps:
      - node/install:
          node-version: << parameters.node-version >>
      - run: npm test

workflows:
  test-matrix:
    jobs:
      - test:
          matrix:
            parameters:
              node-version: ["16", "18", "20"]
              os: [node/default, machine-executor]
            exclude:
              - node-version: "16"
                os: machine-executor
```

---

## CircleCI vs GitHub Actions vs GitLab CI

| Feature | CircleCI | GitHub Actions | GitLab CI |
|---------|----------|----------------|-----------|
| Config file | `.circleci/config.yml` | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| Orbs/Packages | Orbs | Actions | Templates |
| Parallelism | Native (parallelism) | Matrix | parallel: |
| Docker Layer Cache | Yes (paid) | No | No |
| Self-hosted | CircleCI runners | Self-hosted runners | GitLab runners |
| Free tier | 6000 mins/month | 2000 mins/month | 400 mins/month |
