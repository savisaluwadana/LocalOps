# Jenkins In-Depth Theory

## CI/CD Fundamentals

### What is Continuous Integration?

**Continuous Integration (CI)** means developers frequently merge code changes into a shared repository. Each merge triggers an automated build and test.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     CONTINUOUS INTEGRATION                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Developer    Developer    Developer                                        │
│      │            │            │                                             │
│      │   commit   │   commit   │   commit                                    │
│      ▼            ▼            ▼                                             │
│   ┌──────────────────────────────────┐                                       │
│   │         Git Repository           │                                       │
│   └──────────────┬───────────────────┘                                       │
│                  │ webhook/poll                                              │
│                  ▼                                                           │
│   ┌──────────────────────────────────┐                                       │
│   │         Jenkins Server           │                                       │
│   │   ┌────────────────────────┐     │                                       │
│   │   │    Pipeline Stages     │     │                                       │
│   │   │                        │     │                                       │
│   │   │  1. Checkout Code      │     │                                       │
│   │   │  2. Install Deps       │     │                                       │
│   │   │  3. Run Linting        │     │                                       │
│   │   │  4. Run Tests          │     │                                       │
│   │   │  5. Build Artifact     │     │                                       │
│   │   │  6. Publish Reports    │     │                                       │
│   │   │                        │     │                                       │
│   │   └────────────────────────┘     │                                       │
│   └──────────────────────────────────┘                                       │
│                  │                                                           │
│                  ▼                                                           │
│        Feedback (pass/fail)                                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### What is Continuous Delivery/Deployment?

**Continuous Delivery (CD)**: Code is always in a deployable state; deployment requires manual approval.

**Continuous Deployment**: Every change that passes tests is automatically deployed to production.

---

## Jenkins Architecture

### Master-Agent Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      JENKINS ARCHITECTURE                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      JENKINS CONTROLLER (Master)                     │   │
│   │                                                                      │   │
│   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │   │
│   │  │     UI       │  │   Scheduler  │  │    Build Queue           │  │   │
│   │  │  (Web App)   │  │              │  │                          │  │   │
│   │  └──────────────┘  └──────────────┘  └──────────────────────────┘  │   │
│   │                                                                      │   │
│   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │   │
│   │  │  Credentials │  │    Plugins   │  │   Configuration          │  │   │
│   │  │    Store     │  │   Manager    │  │   (jobs, pipelines)      │  │   │
│   │  └──────────────┘  └──────────────┘  └──────────────────────────┘  │   │
│   │                                                                      │   │
│   └───────────────────────────────┬─────────────────────────────────────┘   │
│                                   │ JNLP/SSH                                │
│           ┌───────────────────────┼───────────────────────┐                 │
│           │                       │                       │                 │
│           ▼                       ▼                       ▼                 │
│   ┌───────────────┐       ┌───────────────┐       ┌───────────────┐        │
│   │   Agent 1     │       │   Agent 2     │       │   Agent 3     │        │
│   │  (Linux)      │       │  (Docker)     │       │  (macOS)      │        │
│   │               │       │               │       │               │        │
│   │ label: linux  │       │ label: docker │       │ label: macos  │        │
│   │ executors: 4  │       │ executors: 2  │       │ executors: 2  │        │
│   └───────────────┘       └───────────────┘       └───────────────┘        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **Controller** | Schedules jobs, manages UI, stores configuration |
| **Agent** | Executes builds (can be VMs, containers, bare metal) |
| **Executor** | A slot that can run one build at a time |
| **Workspace** | Directory where build runs on an agent |
| **Pipeline** | The definition of your CI/CD workflow |

---

## Pipeline as Code

### Declarative Pipeline Syntax

```groovy
pipeline {
    // Where to run
    agent any

    // Pipeline options
    options {
        timeout(time: 1, unit: 'HOURS')
        retry(2)
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    // Environment variables
    environment {
        APP_NAME = 'myapp'
        DOCKER_REGISTRY = 'docker.io/myuser'
        // From credentials store
        DOCKER_CREDS = credentials('docker-hub-creds')
        DB_PASSWORD = credentials('database-password')
    }

    // Build parameters
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run test suite')
        password(name: 'DEPLOY_KEY', description: 'Deployment API key')
    }

    // Define stages
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.BRANCH}"]],
                    userRemoteConfigs: [[url: 'https://github.com/user/repo.git']]
                ])
                script {
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
            }
        }

        stage('Test') {
            when {
                expression { params.RUN_TESTS }
            }
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm run test:unit'
                    }
                    post {
                        always {
                            junit 'test-results/unit/*.xml'
                        }
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh 'npm run test:integration'
                    }
                }
                stage('E2E Tests') {
                    agent {
                        docker {
                            image 'cypress/included:latest'
                        }
                    }
                    steps {
                        sh 'cypress run'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_NUMBER}")
                    docker.withRegistry('https://docker.io', 'docker-hub-creds') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh """
                    kubectl set image deployment/${APP_NAME} \
                        ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_NUMBER} \
                        -n staging
                """
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sh """
                    kubectl set image deployment/${APP_NAME} \
                        ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_NUMBER} \
                        -n production
                """
            }
        }
    }

    // Post-build actions
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ Build #${env.BUILD_NUMBER} succeeded - ${env.JOB_NAME}"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Build #${env.BUILD_NUMBER} failed - ${env.JOB_NAME}\n${env.BUILD_URL}"
            )
        }
    }
}
```

---

## Advanced Pipeline Patterns

### Shared Libraries

Create reusable pipeline code:

**vars/deployApp.groovy:**
```groovy
def call(Map config) {
    pipeline {
        agent any
        
        stages {
            stage('Deploy') {
                steps {
                    script {
                        sh "kubectl set image deployment/${config.appName} ${config.container}=${config.image}"
                    }
                }
            }
            
            stage('Verify') {
                steps {
                    sh "kubectl rollout status deployment/${config.appName} --timeout=300s"
                }
            }
        }
    }
}
```

**Using shared library:**
```groovy
@Library('my-shared-library') _

deployApp(
    appName: 'frontend',
    container: 'nginx',
    image: 'myapp/frontend:v1.2.3'
)
```

### Matrix Builds

Test across multiple configurations:

```groovy
pipeline {
    agent none
    
    stages {
        stage('Test Matrix') {
            matrix {
                axes {
                    axis {
                        name 'PYTHON_VERSION'
                        values '3.9', '3.10', '3.11', '3.12'
                    }
                    axis {
                        name 'OS'
                        values 'ubuntu-latest', 'macos-latest'
                    }
                }
                excludes {
                    exclude {
                        axis {
                            name 'PYTHON_VERSION'
                            values '3.9'
                        }
                        axis {
                            name 'OS'
                            values 'macos-latest'
                        }
                    }
                }
                stages {
                    stage('Setup') {
                        agent {
                            label "${OS}"
                        }
                        steps {
                            sh "python${PYTHON_VERSION} --version"
                        }
                    }
                    stage('Test') {
                        steps {
                            sh "tox -e py${PYTHON_VERSION.replace('.', '')}"
                        }
                    }
                }
            }
        }
    }
}
```

### Blue-Green Deployment

```groovy
pipeline {
    agent any
    
    environment {
        ACTIVE_COLOR = sh(script: 'kubectl get svc myapp -o jsonpath={.spec.selector.color}', returnStdout: true).trim()
        NEW_COLOR = "${ACTIVE_COLOR == 'blue' ? 'green' : 'blue'}"
    }
    
    stages {
        stage('Deploy New Version') {
            steps {
                sh """
                    kubectl set image deployment/myapp-${NEW_COLOR} \
                        myapp=${DOCKER_REGISTRY}/myapp:${BUILD_NUMBER}
                    kubectl rollout status deployment/myapp-${NEW_COLOR}
                """
            }
        }
        
        stage('Smoke Test') {
            steps {
                sh "curl -f http://myapp-${NEW_COLOR}.internal/health"
            }
        }
        
        stage('Switch Traffic') {
            steps {
                input message: "Switch traffic to ${NEW_COLOR}?"
                sh """
                    kubectl patch svc myapp -p '{"spec":{"selector":{"color":"${NEW_COLOR}"}}}'
                """
            }
        }
        
        stage('Cleanup Old Version') {
            steps {
                sh "kubectl scale deployment/myapp-${ACTIVE_COLOR} --replicas=0"
            }
        }
    }
    
    post {
        failure {
            // Rollback on failure
            sh """
                kubectl patch svc myapp -p '{"spec":{"selector":{"color":"${ACTIVE_COLOR}"}}}'
            """
        }
    }
}
```

---

## Jenkins with Docker

### Docker as Build Environment

```groovy
pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-v $HOME/.npm:/root/.npm'  // Cache npm
        }
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
            }
        }
    }
}
```

### Build Docker Images

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build Image') {
            steps {
                script {
                    // Build image
                    def customImage = docker.build("myapp:${env.BUILD_NUMBER}")
                    
                    // Run tests inside container
                    customImage.inside {
                        sh 'pytest tests/'
                    }
                    
                    // Push to registry
                    docker.withRegistry('https://registry.example.com', 'registry-creds') {
                        customImage.push()
                        customImage.push('latest')
                    }
                }
            }
        }
    }
}
```

### Docker Compose in Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Integration Test') {
            steps {
                sh 'docker compose -f docker-compose.test.yml up -d'
                sh 'sleep 10'  // Wait for services
                sh 'npm run test:integration'
            }
            post {
                always {
                    sh 'docker compose -f docker-compose.test.yml down -v'
                }
            }
        }
    }
}
```

---

## Credentials Management

### Types of Credentials

```groovy
pipeline {
    environment {
        // Username and password
        GIT_CREDS = credentials('git-credentials')
        // Creates: GIT_CREDS_USR, GIT_CREDS_PSW
        
        // Secret text
        API_KEY = credentials('api-key')
        
        // Secret file
        KUBECONFIG = credentials('kubeconfig-file')
    }
    
    stages {
        stage('Use Credentials') {
            steps {
                // Username/password
                sh 'git clone https://${GIT_CREDS_USR}:${GIT_CREDS_PSW}@github.com/repo.git'
                
                // SSH key
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ssh-key',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh 'ssh -i $SSH_KEY $SSH_USER@server "deploy.sh"'
                }
                
                // File credential
                sh 'kubectl --kubeconfig=$KUBECONFIG get pods'
            }
        }
    }
}
```

---

## Complete Example: Full CI/CD Pipeline

```groovy
pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }
    
    environment {
        DOCKER_REGISTRY = 'docker.io/myuser'
        APP_NAME = 'mywebapp'
        DOCKER_CREDS = credentials('docker-hub')
        KUBE_CONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Prepare') {
            steps {
                checkout scm
                script {
                    env.VERSION = sh(script: 'cat VERSION', returnStdout: true).trim()
                    env.IMAGE_TAG = "${env.VERSION}-${env.BUILD_NUMBER}"
                    currentBuild.displayName = "#${BUILD_NUMBER} - ${env.VERSION}"
                }
            }
        }
        
        stage('Quality Gates') {
            parallel {
                stage('Lint') {
                    agent { docker { image 'node:18' } }
                    steps {
                        sh 'npm ci && npm run lint'
                    }
                }
                stage('Security Scan') {
                    steps {
                        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
                    }
                }
                stage('Unit Tests') {
                    agent { docker { image 'node:18' } }
                    steps {
                        sh 'npm ci && npm test -- --coverage'
                    }
                    post {
                        always {
                            publishHTML(target: [
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage',
                                reportFiles: 'lcov-report/index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                sh """
                    docker build -t ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG} .
                    docker tag ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${APP_NAME}:latest
                """
            }
        }
        
        stage('Push') {
            steps {
                sh """
                    echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG}
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
                """
            }
        }
        
        stage('Deploy Staging') {
            steps {
                sh """
                    export KUBECONFIG=${KUBE_CONFIG}
                    kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG} -n staging
                    kubectl rollout status deployment/${APP_NAME} -n staging --timeout=120s
                """
            }
        }
        
        stage('Deploy Production') {
            when { branch 'main' }
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input message: 'Deploy to Production?', submitter: 'admin,deploy-team'
                }
                sh """
                    export KUBECONFIG=${KUBE_CONFIG}
                    kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG} -n production
                    kubectl rollout status deployment/${APP_NAME} -n production --timeout=120s
                """
            }
        }
    }
    
    post {
        success {
            slackSend(color: '#00FF00', message: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        failure {
            slackSend(color: '#FF0000', message: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}\n${env.BUILD_URL}")
        }
        always {
            cleanWs()
        }
    }
}
```
