# Jenkins Complete Guide

## Table of Contents

1. [Jenkins Fundamentals](#jenkins-fundamentals)
2. [Architecture](#architecture)
3. [Pipeline Basics](#pipeline-basics)
4. [Declarative vs Scripted](#declarative-vs-scripted)
5. [Pipeline Syntax](#pipeline-syntax)
6. [Shared Libraries](#shared-libraries)
7. [Agents and Executors](#agents-and-executors)
8. [Integration Patterns](#integration-patterns)
9. [Best Practices](#best-practices)

---

## Jenkins Fundamentals

### What is Jenkins?

**Jenkins** is an open-source automation server that helps automate building, testing, and deploying software. It's the most widely used CI/CD tool.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Job** | A runnable task (build, test, deploy) |
| **Build** | One execution of a job |
| **Pipeline** | A series of connected jobs |
| **Agent** | A machine that runs builds |
| **Executor** | A slot for running builds |
| **Workspace** | Directory where build runs |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       JENKINS ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                     JENKINS CONTROLLER                          │    │
│   │                                                                  │    │
│   │  • Schedules builds                                             │    │
│   │  • Distributes work to agents                                   │    │
│   │  • Monitors agents                                              │    │
│   │  • Records build results                                        │    │
│   │  • Serves UI                                                    │    │
│   └────────────────────────────────────────────────────────────────┘    │
│          │              │               │                                │
│          ▼              ▼               ▼                                │
│   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                   │
│   │   Agent 1    │ │   Agent 2    │ │   Agent 3    │                   │
│   │  (Linux)     │ │  (Windows)   │ │  (Docker)    │                   │
│   │              │ │              │ │              │                   │
│   │ Executor 1   │ │ Executor 1   │ │ Executor 1   │                   │
│   │ Executor 2   │ │ Executor 2   │ │ Executor 2   │                   │
│   └──────────────┘ └──────────────┘ └──────────────┘                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Pipeline Basics

### Jenkinsfile

A Jenkinsfile defines your pipeline as code, stored alongside your application.

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Deploy') {
            steps {
                sh './deploy.sh'
            }
        }
    }
}
```

### Pipeline Components

```
pipeline {
    agent { ... }          // WHERE to run
    
    environment { ... }    // Environment variables
    
    stages {               // WHAT to do
        stage('Name') {
            steps { ... }
        }
    }
    
    post { ... }           // Actions after pipeline
}
```

---

## Declarative vs Scripted

| Aspect | Declarative | Scripted |
|--------|-------------|----------|
| Syntax | Structured, limited | Full Groovy |
| Learning curve | Easier | Steeper |
| Error messages | Better | More cryptic |
| Flexibility | Less | More |
| Use case | Most pipelines | Complex logic |

### Declarative Example

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'make build'
            }
        }
    }
}
```

### Scripted Example

```groovy
node {
    stage('Build') {
        sh 'make build'
    }
    
    // Full Groovy power
    def items = ['a', 'b', 'c']
    items.each { item ->
        stage("Process ${item}") {
            sh "process ${item}"
        }
    }
}
```

---

## Pipeline Syntax

### Agents

```groovy
// Any available agent
agent any

// Specific label
agent { label 'linux' }

// Docker container
agent {
    docker {
        image 'node:18'
        args '-v /tmp:/tmp'
    }
}

// Kubernetes pod
agent {
    kubernetes {
        yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: maven
            image: maven:3.8-jdk-11
            command: ['cat']
            tty: true
        '''
    }
}

// No agent at top level
agent none
```

### Stages and Steps

```groovy
stages {
    stage('Build') {
        steps {
            // Shell commands
            sh 'npm install'
            sh '''
                npm run build
                npm run lint
            '''
            
            // Change directory
            dir('subdir') {
                sh 'make'
            }
            
            // Echo
            echo 'Building...'
        }
    }
    
    stage('Parallel Tests') {
        parallel {
            stage('Unit Tests') {
                steps {
                    sh 'npm run test:unit'
                }
            }
            stage('Integration Tests') {
                steps {
                    sh 'npm run test:integration'
                }
            }
        }
    }
}
```

### Environment Variables

```groovy
pipeline {
    environment {
        // Global
        APP_NAME = 'my-app'
        VERSION = sh(script: 'cat VERSION', returnStdout: true).trim()
    }
    
    stages {
        stage('Build') {
            environment {
                // Stage-specific
                BUILD_ENV = 'production'
            }
            steps {
                sh 'echo $APP_NAME $VERSION'
            }
        }
    }
}
```

### Credentials

```groovy
pipeline {
    environment {
        // Username/password
        CREDS = credentials('my-creds-id')
        // Gives: CREDS_USR and CREDS_PSW
        
        // Secret text
        API_KEY = credentials('api-key-id')
    }
    
    stages {
        stage('Deploy') {
            steps {
                sh 'docker login -u $CREDS_USR -p $CREDS_PSW'
                
                // Or in a withCredentials block
                withCredentials([usernamePassword(
                    credentialsId: 'my-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh 'deploy --user $USER --pass $PASS'
                }
            }
        }
    }
}
```

### Conditionals

```groovy
stage('Deploy to Prod') {
    when {
        branch 'main'
    }
    steps {
        sh './deploy-prod.sh'
    }
}

stage('Deploy Feature') {
    when {
        branch pattern: 'feature/*', comparator: 'GLOB'
    }
    steps {
        sh './deploy-feature.sh'
    }
}

stage('Manual Approval') {
    when {
        expression { params.DEPLOY_PROD == true }
    }
    steps {
        input message: 'Deploy to production?'
    }
}
```

### Post Actions

```groovy
pipeline {
    stages { ... }
    
    post {
        always {
            // Always run (cleanup)
            cleanWs()
        }
        success {
            slackSend message: 'Build succeeded!'
        }
        failure {
            slackSend message: 'Build failed!'
        }
        unstable {
            // Test failures
        }
        changed {
            // Status changed from last build
        }
    }
}
```

---

## Shared Libraries

Reusable code across pipelines.

### Library Structure

```
(root)
├── vars/
│   ├── buildApp.groovy      # Global variables/functions
│   └── deployApp.groovy
├── src/
│   └── org/company/         # Groovy classes
│       └── Utils.groovy
└── resources/               # Non-Groovy files
    └── templates/
```

### Creating a Step

```groovy
// vars/buildApp.groovy
def call(Map config = [:]) {
    def appName = config.name ?: 'default-app'
    def buildType = config.type ?: 'npm'
    
    pipeline {
        agent any
        
        stages {
            stage('Build') {
                steps {
                    script {
                        if (buildType == 'npm') {
                            sh 'npm install && npm run build'
                        } else if (buildType == 'maven') {
                            sh 'mvn clean package'
                        }
                    }
                }
            }
        }
    }
}
```

### Using the Library

```groovy
@Library('my-shared-library') _

buildApp(name: 'my-app', type: 'npm')
```

---

## Agents and Executors

### Agent Configuration

```groovy
// In Jenkins configuration
// Manage Jenkins → Nodes

// Dynamic agents with Kubernetes
agent {
    kubernetes {
        yaml '''
        spec:
          containers:
          - name: node
            image: node:18
            resources:
              limits:
                memory: "2Gi"
                cpu: "1"
        '''
        defaultContainer 'node'
    }
}
```

### Best Practices

| Practice | Reason |
|----------|--------|
| Use ephemeral agents | Clean environment each build |
| Right-size resources | Don't waste or starve |
| Label agents | Match jobs to capabilities |
| Limit executors on controller | Controller for coordination only |

---

## Integration Patterns

### Docker

```groovy
pipeline {
    agent {
        docker {
            image 'node:18'
        }
    }
    
    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("my-app:${BUILD_NUMBER}")
                }
            }
        }
        
        stage('Push') {
            steps {
                script {
                    docker.withRegistry('https://registry.example.com', 'registry-creds') {
                        docker.image("my-app:${BUILD_NUMBER}").push()
                    }
                }
            }
        }
    }
}
```

### Kubernetes Deployment

```groovy
stage('Deploy to K8s') {
    steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
            sh 'kubectl apply -f k8s/'
            sh 'kubectl rollout status deployment/my-app'
        }
    }
}
```

---

## Best Practices

### Pipeline Design

1. **Keep Jenkinsfile in repo** - Version controlled with code
2. **Use declarative syntax** - Easier to read and maintain
3. **Fail fast** - Run quick validations first
4. **Parallelize** - Run independent stages concurrently
5. **Use shared libraries** - DRY across pipelines

### Security

1. **Never hardcode secrets** - Use credentials plugin
2. **Limit access** - Role-based access control
3. **Audit** - Track who ran what
4. **Update regularly** - Security patches

### Maintenance

1. **Clean workspaces** - Prevent disk issues
2. **Archive artifacts selectively** - Keep what matters
3. **Set build retention** - Don't keep forever
4. **Monitor queue time** - Add agents if needed

This guide covers Jenkins from fundamentals to advanced patterns for building robust CI/CD pipelines.
