# CI/CD Pipeline Examples

This section contains complete, production-ready CI/CD pipeline examples.

---

## 1. Full Stack Application Pipeline (Jenkins)

### Jenkinsfile

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        IMAGE_NAME = 'myapp'
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Build & Test') {
            parallel {
                stage('Backend') {
                    agent { docker { image 'python:3.11' } }
                    steps {
                        dir('backend') {
                            sh 'pip install -r requirements.txt'
                            sh 'pytest --junitxml=results.xml'
                        }
                    }
                    post {
                        always { junit 'backend/results.xml' }
                    }
                }
                stage('Frontend') {
                    agent { docker { image 'node:18' } }
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                            sh 'npm test -- --coverage'
                            sh 'npm run build'
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}-backend:${IMAGE_TAG}", "./backend")
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}-frontend:${IMAGE_TAG}", "./frontend")
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh "docker scout cves ${DOCKER_REGISTRY}/${IMAGE_NAME}-backend:${IMAGE_TAG}"
            }
        }
        
        stage('Push Images') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-creds') {
                        docker.image("${DOCKER_REGISTRY}/${IMAGE_NAME}-backend:${IMAGE_TAG}").push()
                        docker.image("${DOCKER_REGISTRY}/${IMAGE_NAME}-frontend:${IMAGE_TAG}").push()
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                sh """
                    kubectl set image deployment/backend backend=${DOCKER_REGISTRY}/${IMAGE_NAME}-backend:${IMAGE_TAG} -n staging
                    kubectl set image deployment/frontend frontend=${DOCKER_REGISTRY}/${IMAGE_NAME}-frontend:${IMAGE_TAG} -n staging
                    kubectl rollout status deployment/backend -n staging --timeout=300s
                """
            }
        }
        
        stage('Integration Tests') {
            steps {
                sh 'npm run test:e2e -- --baseUrl=https://staging.example.com'
            }
        }
        
        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                sh """
                    kubectl set image deployment/backend backend=${DOCKER_REGISTRY}/${IMAGE_NAME}-backend:${IMAGE_TAG} -n production
                    kubectl set image deployment/frontend frontend=${DOCKER_REGISTRY}/${IMAGE_NAME}-frontend:${IMAGE_TAG} -n production
                """
            }
        }
    }
    
    post {
        success {
            slackSend channel: '#deployments', color: 'good',
                message: "✅ ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed successfully"
        }
        failure {
            slackSend channel: '#deployments', color: 'danger',
                message: "❌ ${env.JOB_NAME} #${env.BUILD_NUMBER} failed"
        }
    }
}
```

---

## 2. GitHub Actions Workflow

`.github/workflows/ci-cd.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install & Test
        run: |
          pip install -r requirements.txt
          pytest --cov=app --cov-report=xml
          
      - name: Upload Coverage
        uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to Registry
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
            type=sha,prefix=
            type=ref,event=branch
            
      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to K8s
        uses: azure/k8s-deploy@v4
        with:
          manifests: k8s/staging/
          images: ${{ needs.build.outputs.image_tag }}

  deploy-production:
    needs: [build, deploy-staging]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to K8s
        uses: azure/k8s-deploy@v4
        with:
          manifests: k8s/production/
          images: ${{ needs.build.outputs.image_tag }}
```

---

## 3. Multi-Environment Terraform Pipeline

```groovy
pipeline {
    agent any
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'])
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'])
    }
    
    stages {
        stage('Terraform Init') {
            steps {
                dir("terraform/environments/${params.ENVIRONMENT}") {
                    sh 'terraform init -backend-config=backend.tfvars'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir("terraform/environments/${params.ENVIRONMENT}") {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                dir("terraform/environments/${params.ENVIRONMENT}") {
                    input message: "Apply to ${params.ENVIRONMENT}?"
                    sh 'terraform apply tfplan'
                }
            }
        }
    }
}
```
