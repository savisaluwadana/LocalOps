# Argo Workflows Complete Guide

## Table of Contents

1. [Argo Workflows Fundamentals](#argo-workflows-fundamentals)
2. [Architecture](#architecture)
3. [Workflow Concepts](#workflow-concepts)
4. [Workflow Templates](#workflow-templates)
5. [Artifacts and Outputs](#artifacts-and-outputs)
6. [Events and Triggers](#events-and-triggers)
7. [Comparison with Other Tools](#comparison-with-other-tools)
8. [Best Practices](#best-practices)

---

## Argo Workflows Fundamentals

### What is Argo Workflows?

**Argo Workflows** is an open-source container-native workflow engine for orchestrating parallel jobs on Kubernetes. It is implemented as a Kubernetes CRD (`Workflow`).

### Use Cases

- **Machine Learning Pipelines** (Kubeflow is built on Argo)
- **Data Processing / ETL**
- **CI/CD Pipelines**
- **Infrastructure Automation**

### Key Features

- **Container Native**: Every step is a pod.
- **DAG / Steps**: Define dependencies as a Directed Acyclic Graph or sequential steps.
- **Artifact Support**: Pass files (S3, GCS, Artifactory) between steps.
- **Dynamic Parallelism**: Scatter-gather patterns.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      ARGO WORKFLOWS ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐                 │
│   │ Workflow     │   │ CronWorkflow │   │ Workflow     │                 │
│   │ Controller   │   │ Controller   │   │ Archive (DB) │                 │
│   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘                 │
│          │ Watch            │ Creates          │ Store                   │
│          ▼                  ▼                  ▼                         │
│   ┌──────────────────────────────────────────────────────┐              │
│   │                 KUBERNETES API SERVER                │              │
│   └──────────────────────────┬───────────────────────────┘              │
│                              │                                           │
│                              ▼                                           │
│   ┌──────────────────────────────────────────────────────┐              │
│   │                        NODES                         │              │
│   │                                                      │              │
│   │  ┌──────────┐   ┌──────────┐   ┌──────────┐          │              │
│   │  │ Pod A    │   │ Pod B    │   │ Pod C    │          │              │
│   │  │ (Step 1) │   │ (Step 2) │   │ (Step 3) │          │              │
│   │  └───┬──────┘   └───▲───┬──┘   └───▲──────┘          │              │
│   │      │              │   │          │                 │              │
│   └──────┼──────────────┼───┼──────────┼─────────────────┘              │
│          │              │   │          │                                 │
│          ▼              ▼   ▼          ▼                                 │
│   ┌──────────────────────────────────────────────────────┐              │
│   │                  ARTIFACT REPOSITORY                 │              │
│   │                 (S3 / MinIO / GCS)                   │              │
│   └──────────────────────────────────────────────────────┘              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Workflow Concepts

### Variable Substitution

Argo uses `{{}}` syntax for variables.

### The `Workflow` CRD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: hello-world-  # Unique name generated
spec:
  entrypoint: whalesay        # Start here
  templates:
    - name: whalesay
      container:
        image: docker/whalesay
        command: [cowsay]
        args: ["hello world"]
```

### Steps (Sequential/Parallel)

```yaml
spec:
  entrypoint: hello-hello-hello
  templates:
    - name: hello-hello-hello
      steps:
        - - name: step1
            template: hello
        - - name: step2a
            template: hello
          - name: step2b        # Runs parallel to step2a
            template: hello
```

### DAG (Directed Acyclic Graph)

More flexible dependency management.

```yaml
spec:
  entrypoint: diamond
  templates:
    - name: diamond
      dag:
        tasks:
          - name: A
            template: echo
          - name: B
            dependencies: [A]
            template: echo
          - name: C
            dependencies: [A]
            template: echo
          - name: D
            dependencies: [B, C]
            template: echo
```

---

## Workflow Templates

Reusable definitions stored in the cluster.

```yaml
# WorkflowTemplate
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: build-template
spec:
  templates:
    - name: build
      inputs:
        parameters:
          - name: repo
      container:
        image: builder
        args: ["{{inputs.parameters.repo}}"]
```

**Using the Template:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: build-run-
spec:
  entrypoint: main
  templates:
  - name: main
    steps:
    - - name: call-template
        templateRef:
          name: build-template
          template: build
        arguments:
          parameters:
          - name: repo
            value: "https://github.com/my/repo"
```

---

## Artifacts and Outputs

Passing data between steps.

### Outputs (Producer)

```yaml
templates:
  - name: generate-artifact
    container:
      image: alpine
      command: [sh, -c]
      args: ["echo 'hello' > /tmp/hello.txt"]
    outputs:
      artifacts:
        - name: message
          path: /tmp/hello.txt
```

### Inputs (Consumer)

```yaml
templates:
  - name: consume-artifact
    inputs:
      artifacts:
        - name: message
          path: /tmp/message
    container:
      image: alpine
      command: [cat, /tmp/message]
```

### S3 Configuration (Globally or per Workflow)

```yaml
artifactRepository:
  s3:
    bucket: my-bucket
    endpoint: s3.amazonaws.com
    accessKeySecret:
      name: my-s3-credentials
      key: accessKey
    secretKeySecret:
      name: my-s3-credentials
      key: secretKey
```

---

## Events and Triggers

### Argo Events

Separate project often used with Workflows to trigger them based on external events (Webhooks, S3 uploads, Kafka messages, Schedules).

```
EventSource (Webhook) ──▶ Sensor ──▶ Trigger (Create Workflow)
```

### CronWorkflow

Native scheduling.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: CronWorkflow
metadata:
  name: nightly-build
spec:
  schedule: "0 0 * * *"
  timezone: "America/Los_Angeles"
  workflowSpec:
    entrypoint: main
    templates:
      - name: main
        container:
          image: busybox
          command: [echo, "Running nightly build"]
```

---

## Comparison with Other Tools

| Feature | Argo Workflows | Jenkins | Airflow | Tekton |
|---------|---------------|---------|---------|--------|
| **Native** | Kubernetes | JVM | Python | Kubernetes |
| **Definition** | YAML | Groovy | Python | YAML |
| **Use Case** | Data/ML/General | CI/CD | ETL/Data | CI/CD |
| **Execution** | Pod per step | Executor | Worker | Pod per task |
| **Parallelism** | High | Medium | Medium | High |

---

## Best Practices

1.  **Use WorkflowTemplates**: Don't duplicate code in every workflow.
2.  **Resource Limits**: Always set CPU/Memory requests/limits for containers.
3.  **Pod GC**: Clean up completed pods.
    ```yaml
    spec:
      podGC:
        strategy: OnPodCompletion
    ```
4.  **Workflow TTL**: Auto-delete workflow objects after completion.
    ```yaml
    spec:
      ttlStrategy:
        secondsAfterCompletion: 3600 # 1 hour
    ```
5.  **Memoization**: Cache step results to avoid re-running expensive tasks.
6.  **Retries**: Handle transient failures.
    ```yaml
    retryStrategy:
      limit: "3"
      retryPolicy: "Always"
    ```

### Example: Complete CI Workflow

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: ci-pipeline-
spec:
  entrypoint: ci-example
  volumeClaimTemplates:
    - metadata:
        name: workdir
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 1Gi

  templates:
  - name: ci-example
    steps:
    - - name: checkout
        template: checkout
    - - name: build
        template: build
    - - name: test
        template: test

  - name: checkout
    script:
      image: alpine/git
      workingDir: /workdir
      volumeMounts:
      - name: workdir
        mountPath: /workdir
      source: |
        git clone https://github.com/argoproj/argo-workflows.git .

  - name: build
    container:
      image: golang:1.18
      workingDir: /workdir
      command: [go, build, ./...]
      volumeMounts:
      - name: workdir
        mountPath: /workdir

  - name: test
    container:
      image: golang:1.18
      workingDir: /workdir
      command: [go, test, ./...]
      volumeMounts:
      - name: workdir
        mountPath: /workdir
```
