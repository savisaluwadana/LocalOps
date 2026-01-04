# Jenkins Fundamentals

## What is Jenkins?

Jenkins is an open-source **automation server** for Continuous Integration/Continuous Delivery (CI/CD). It automates build, test, and deployment phases.

### CI/CD Pipeline Flow

```
Developer → Commit → BUILD → TEST → DEPLOY → Production
           ◄── Continuous Integration ──►
           ◄────── Continuous Delivery ──────────────►
```

---

## Core Concepts

### 1. Pipeline as Code (Jenkinsfile)

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'npm install'
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
    
    post {
        success { echo 'Success!' }
        failure { echo 'Failed!' }
    }
}
```

### 2. Agents

```groovy
// Run anywhere
agent any

// Run in Docker container
agent {
    docker { image 'node:18' }
}

// Run on labeled node
agent { label 'linux' }
```

### 3. Credentials

```groovy
environment {
    DOCKER_CREDS = credentials('docker-hub-creds')
}
steps {
    sh 'docker login -u $DOCKER_CREDS_USR -p $DOCKER_CREDS_PSW'
}
```

---

## Hands-On: Deploy Jenkins

Create `playground/jenkins/docker-compose.yml`:

```yaml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins
    privileged: true
    user: root
    ports:
      - "8080:8080"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped

volumes:
  jenkins_home:
```

```bash
docker compose up -d
# Access: http://localhost:8080
# Get password: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## Sample Pipeline

```groovy
pipeline {
    agent {
        docker { image 'python:3.11-slim' }
    }
    
    parameters {
        choice(name: 'ENV', choices: ['dev', 'prod'])
        booleanParam(name: 'RUN_TESTS', defaultValue: true)
    }
    
    stages {
        stage('Install') {
            steps { sh 'pip install -r requirements.txt' }
        }
        
        stage('Test') {
            when { expression { params.RUN_TESTS } }
            steps { sh 'pytest' }
        }
        
        stage('Deploy') {
            when { branch 'main' }
            steps {
                input message: 'Deploy?', ok: 'Yes'
                sh "./deploy.sh ${params.ENV}"
            }
        }
    }
}
```

---

## Further Learning

- [Jenkins Docs](https://jenkins.io/doc/)
- Pipeline Syntax Generator: `/pipeline-syntax` in Jenkins UI
