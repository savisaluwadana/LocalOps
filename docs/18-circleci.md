# CircleCI Complete Guide

## Table of Contents

1. [CircleCI Fundamentals](#circleci-fundamentals)
2. [Configuration Basics](#configuration-basics)
3. [Jobs and Workflows](#jobs-and-workflows)
4. [Executors](#executors)
5. [Commands and Orbs](#commands-and-orbs)
6. [Caching and Workspaces](#caching-and-workspaces)
7. [Contexts and Secrets](#contexts-and-secrets)
8. [Advanced Patterns](#advanced-patterns)
9. [Best Practices](#best-practices)

---

## CircleCI Fundamentals

### What is CircleCI?

**CircleCI** is a cloud-native CI/CD platform known for its performance and flexibility. Configuration lives in `.circleci/config.yml`.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Pipeline** | Full CI run triggered by push |
| **Workflow** | Orchestration of jobs |
| **Job** | Collection of steps |
| **Step** | Individual command |
| **Executor** | Environment for jobs |
| **Orb** | Reusable config packages |

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      CIRCLECI ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐                                                       │
│   │   Pipeline   │  triggered by push/API                               │
│   └──────┬───────┘                                                       │
│          │                                                               │
│          ▼                                                               │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │                     WORKFLOWS                                 │      │
│   │                                                              │      │
│   │   build-test-deploy:                                         │      │
│   │   ┌──────┐    ┌──────┐    ┌───────┐    ┌────────┐          │      │
│   │   │build │ ─▶ │ test │ ─▶ │deploy │ ─▶ │ deploy │          │      │
│   │   │      │    │      │    │staging│    │  prod  │          │      │
│   │   └──────┘    └──────┘    └───────┘    └────────┘          │      │
│   │                                              │              │      │
│   │                                         (requires          │      │
│   │                                          approval)         │      │
│   └──────────────────────────────────────────────────────────────┘      │
│                              │                                           │
│                              ▼                                           │
│   ┌──────────────────────────────────────────────────────────────┐      │
│   │                      EXECUTORS                                │      │
│   │    Docker        Machine       macOS       Self-hosted       │      │
│   │   Container        VM          VM           Runner           │      │
│   └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Configuration Basics

### Basic Structure

```yaml
# .circleci/config.yml
version: 2.1

jobs:
  build:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: npm ci
      - run:
          name: Build
          command: npm run build

  test:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - run: npm ci
      - run: npm test

workflows:
  build-and-test:
    jobs:
      - build
      - test:
          requires:
            - build
```

---

## Jobs and Workflows

### Job Configuration

```yaml
jobs:
  my-job:
    docker:
      - image: cimg/node:20.0
    
    # Working directory
    working_directory: ~/project
    
    # Resource class
    resource_class: medium
    
    # Environment variables
    environment:
      NODE_ENV: production
    
    # Parallelism
    parallelism: 4
    
    steps:
      - checkout
      
      # Run command
      - run:
          name: Run tests
          command: |
            TESTS=$(circleci tests glob "test/**/*.test.js" | circleci tests split)
            npm test -- $TESTS
      
      # Store artifacts
      - store_artifacts:
          path: coverage
          destination: coverage
      
      # Store test results
      - store_test_results:
          path: test-results
```

### Workflow Orchestration

```yaml
workflows:
  build-test-deploy:
    jobs:
      - build
      
      - test:
          requires:
            - build
      
      - lint:
          requires:
            - build
      
      # Parallel jobs after test
      - security-scan:
          requires:
            - test
      
      # Manual approval
      - hold-deploy:
          type: approval
          requires:
            - test
            - security-scan
      
      # Deploy after approval
      - deploy:
          requires:
            - hold-deploy
          filters:
            branches:
              only: main
```

### Conditional Workflows

```yaml
workflows:
  # Only on main branch
  deploy-prod:
    when:
      equal: [main, << pipeline.git.branch >>]
    jobs:
      - deploy

  # Only on tags
  release:
    jobs:
      - build:
          filters:
            tags:
              only: /^v.*/
            branches:
              ignore: /.*/
```

---

## Executors

### Docker Executor

```yaml
jobs:
  test:
    docker:
      # Primary container
      - image: cimg/node:20.0
        auth:
          username: $DOCKERHUB_USERNAME
          password: $DOCKERHUB_PASSWORD
      
      # Service containers
      - image: postgres:15
        environment:
          POSTGRES_USER: test
          POSTGRES_DB: test
      
      - image: redis:7
    
    steps:
      - checkout
      - run: npm test
```

### Machine Executor

```yaml
jobs:
  build-docker:
    machine:
      image: ubuntu-2204:current
    
    steps:
      - checkout
      - run: docker build -t myapp .
      - run: docker push myapp
```

### macOS Executor

```yaml
jobs:
  build-ios:
    macos:
      xcode: "14.3.1"
    
    steps:
      - checkout
      - run: xcodebuild -scheme MyApp build
```

### Reusable Executors

```yaml
executors:
  node-executor:
    docker:
      - image: cimg/node:20.0
    working_directory: ~/project
    environment:
      NODE_ENV: production

jobs:
  build:
    executor: node-executor
    steps:
      - checkout
      - run: npm run build

  test:
    executor: node-executor
    steps:
      - checkout
      - run: npm test
```

---

## Commands and Orbs

### Reusable Commands

```yaml
commands:
  install-deps:
    description: Install npm dependencies
    parameters:
      cache-key:
        type: string
        default: v1
    steps:
      - restore_cache:
          keys:
            - << parameters.cache-key >>-deps-{{ checksum "package-lock.json" }}
      - run: npm ci
      - save_cache:
          paths:
            - node_modules
          key: << parameters.cache-key >>-deps-{{ checksum "package-lock.json" }}

jobs:
  build:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - install-deps:
          cache-key: v2
      - run: npm run build
```

### Using Orbs

```yaml
version: 2.1

orbs:
  node: circleci/node@5.1.0
  docker: circleci/docker@2.2.0
  aws-cli: circleci/aws-cli@4.0.0

jobs:
  build:
    executor: node/default
    steps:
      - checkout
      - node/install-packages
      - run: npm run build

  deploy:
    executor: aws-cli/default
    steps:
      - aws-cli/setup
      - run: aws s3 sync dist/ s3://my-bucket/
```

---

## Caching and Workspaces

### Caching

```yaml
jobs:
  build:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      
      # Restore cache
      - restore_cache:
          keys:
            - npm-deps-{{ checksum "package-lock.json" }}
            - npm-deps-
      
      - run: npm ci
      
      # Save cache
      - save_cache:
          paths:
            - node_modules
          key: npm-deps-{{ checksum "package-lock.json" }}
```

### Workspaces

```yaml
jobs:
  build:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - run: npm ci
      - run: npm run build
      
      # Persist to workspace
      - persist_to_workspace:
          root: .
          paths:
            - dist
            - node_modules

  deploy:
    docker:
      - image: cimg/node:20.0
    steps:
      # Attach workspace
      - attach_workspace:
          at: .
      
      - run: ls dist/  # Built files available
      - run: ./deploy.sh

workflows:
  build-deploy:
    jobs:
      - build
      - deploy:
          requires:
            - build
```

---

## Contexts and Secrets

### Using Contexts

```yaml
# Contexts are configured in CircleCI UI
# Organization Settings → Contexts

workflows:
  deploy:
    jobs:
      - deploy-staging:
          context: staging-env
      
      - deploy-prod:
          context:
            - prod-env
            - aws-credentials
```

### Environment Variables

```yaml
jobs:
  deploy:
    docker:
      - image: cimg/node:20.0
    environment:
      # Job-level
      NODE_ENV: production
    steps:
      - run:
          name: Deploy
          environment:
            # Step-level
            DEPLOY_TARGET: production
          command: |
            echo "Deploying to $DEPLOY_TARGET"
            # Project env vars from CircleCI settings
            echo "Using key: $AWS_ACCESS_KEY_ID"
```

---

## Advanced Patterns

### Pipeline Parameters

```yaml
version: 2.1

parameters:
  deploy-env:
    type: string
    default: staging
  skip-tests:
    type: boolean
    default: false

jobs:
  test:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - when:
          condition:
            not: << pipeline.parameters.skip-tests >>
          steps:
            - run: npm test

  deploy:
    docker:
      - image: cimg/node:20.0
    steps:
      - run: ./deploy.sh << pipeline.parameters.deploy-env >>

# Trigger with: circleci pipeline trigger --param deploy-env=production
```

### Matrix Jobs

```yaml
jobs:
  test:
    parameters:
      node-version:
        type: string
    docker:
      - image: cimg/node:<< parameters.node-version >>
    steps:
      - checkout
      - run: npm test

workflows:
  test-all-versions:
    jobs:
      - test:
          matrix:
            parameters:
              node-version: ["18.0", "20.0", "21.0"]
```

### Dynamic Configuration

```yaml
# .circleci/config.yml
version: 2.1

setup: true

orbs:
  continuation: circleci/continuation@0.3.1

jobs:
  generate-config:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - run:
          name: Generate config
          command: ./generate-pipeline.sh > generated-config.yml
      - continuation/continue:
          configuration_path: generated-config.yml
```

---

## Best Practices

### Performance

1. **Use caching** - Restore dependencies
2. **Use workspaces** - Pass artifacts between jobs
3. **Parallelize tests** - Split across containers
4. **Right-size resources** - Match resource class to needs

```yaml
jobs:
  test:
    parallelism: 4
    steps:
      - run:
          name: Split and run tests
          command: |
            TESTS=$(circleci tests glob "test/**/*.js" | circleci tests split --split-by=timings)
            npm test -- $TESTS
```

### Security

1. **Use contexts** - Organize secrets by environment
2. **Restrict contexts** - Limit to specific branches
3. **Use project variables** - For secrets
4. **OIDC** - For cloud authentication

### Organization

```yaml
# Use YAML anchors
defaults: &defaults
  docker:
    - image: cimg/node:20.0
  working_directory: ~/project

jobs:
  build:
    <<: *defaults
    steps:
      - checkout
      - run: npm run build

  test:
    <<: *defaults
    steps:
      - checkout
      - run: npm test
```

### Cost Optimization

1. **Use resource classes wisely** - Smaller for simple tasks
2. **Cancel redundant builds** - Auto-cancel on new push
3. **Conditional workflows** - Skip when not needed
4. **Cache everything** - Reduce build time

This guide covers CircleCI from fundamentals to advanced patterns for building efficient CI/CD pipelines.
