# Platform Engineering Guide

## Table of Contents

1. [What is Platform Engineering?](#what-is-platform-engineering)
2. [Internal Developer Platform (IDP)](#internal-developer-platform-idp)
3. [Architecture](#architecture)
4. [Golden Paths](#golden-paths)
5. [Team Topologies](#team-topologies)
6. [Tools and Ecosystem](#tools-and-ecosystem)
7. [Measuring Success](#measuring-success)

---

## What is Platform Engineering?

**Platform Engineering** is the discipline of designing and building toolchains and workflows that enable self-service capabilities for software engineering organizations in the cloud-native era.

### Core Philosophy

- **Platform as a Product**: Treat the platform as a product, developers as customers.
- **Cognitive Load Reduction**: Abstract complexity so developers focus on business logic.
- **Self-Service**: Enable developers to perform operations without waiting for Ops.
- **Guardrails, Not Gates**: Embed best practices and security by default.

---

## Internal Developer Platform (IDP)

An **IDP** is the sum of all the tech and tools that a platform engineering team binds together to pave golden paths for developers.

### Key Capabilities

1.  **Application Configuration Management**
2.  **Infrastructure Orchestration**
3.  **Environment Management**
4.  **Deployment Management**
5.  **Role-Based Access Control**

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    INTERNAL DEVELOPER PLATFORM (IDP)                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌───────────────────────────────────────────────────────────────────┐ │
│   │                        User Interface                              │ │
│   │          (Backstage, Port, Compass, CLI, API)                     │ │
│   └──────────────────────────────┬────────────────────────────────────┘ │
│                                  │                                       │
│                                  ▼                                       │
│   ┌───────────────────────────────────────────────────────────────────┐ │
│   │                      Platform Orchestrator                         │ │
│   │               (Humanitec, Kratix, Crossplane)                      │ │
│   │                                                                   │ │
│   │  • Translates abstract requests to concrete config                │ │
│   │  • Manages dependencies                                           │ │
│   │  • Enforces policy                                                │ │
│   └─────────────────┬────────────────┬────────────────┬───────────────┘ │
│                     │                │                │                   │
│          ┌──────────▼─────┐   ┌──────▼──────┐  ┌──────▼───────┐          │
│          │ Infrastructure │   │  CI/CD      │  │ Observability│          │
│          │                │   │             │  │              │          │
│          │ • Terraform    │   │ • Github    │  │ • DataDog    │          │
│          │ • Kubernetes   │   │   Actions   │  │ • Prometheus │          │
│          │ • AWS/GCP      │   │ • ArgoCD    │  │ • Grafana    │          │
│          └───┬────────────┘   └──────┬──────┘  └──────┬───────┘          │
│              │                       │                │                  │
│              └───────────────────────┼────────────────┘                  │
│                                      │                                   │
│                                      ▼                                   │
│                             Runtime Environment                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Golden Paths

**Golden Paths** (or Paved Roads) are "supported", opinionated paths to build and deploy software. They are optional but recommended.

### Example Golden Path: Microservice

1.  **Scaffold**: Developer visits portal -> "Create New Microservice" -> Selects Template (Go/Node/Java).
2.  **Repo**: Platform creates Git repo with skeleton code, Dockerfile, Helm charts, CI/CD pipeline.
3.  **Infra**: Platform provisions required resources (ECR, potential DB).
4.  **Deploy**: Pipeline builds and deploys to "Dev" environment automatically.
5.  **Register**: Service is registered in the Service Catalog.

### Benefits

- **Speed**: "Hello World" to Production in minutes.
- **Standardization**: Consistency across the organization.
- **Updates**: Easier to roll out security patches or library updates globally.

---

## Team Topologies

Based on the book *Team Topologies* by Matthew Skelton and Manuel Pais.

### Four Fundamental Topologies

1.  **Stream-aligned team**: Aligned to a flow of work (e.g., product feature). Focus on delivery.
2.  **Enabling team**: Helps stream-aligned teams overcome obstacles/learn new tech.
3.  **Complicated Subsystem team**: Responsible for highly specialized knowledge (e.g., math heavy algorithm, video processing core).
4.  **Platform team**: Provides internal services to reduce cognitive load on stream-aligned teams.

### Interaction Modes

- **Collaboration**: Working together for a defined period to discover new things.
- **X-as-a-Service**: One team provides a service to another with a clear API/contract.
- **Facilitating**: One team helps another clear impediments.

---

## Tools and Ecosystem

### Developer Portals
- **Backstage** (Spotify) - The standard.
- **Port**
- **Compass** (Atlassian)
- **Cortex**

### Platform Orchestration
- **Humanitec**
- **Kratix**
- **Crossplane** (Control plane)

### Infrastructure as Code
- **Terraform**
- **Pulumi**
- **Crossplane**

### CI/CD
- **GitHub Actions**
- **GitLab CI**
- **ArgoCD**

---

## Measuring Success

### SPACE Framework

- **S**atisfaction and well-being
- **P**erformance
- **A**ctivity
- **C**ommunication and collaboration
- **E**fficiency and flow

### Platform Metrics

- **Adoption Rate**: % of teams using the platform.
- **Time to nth Commit**: Speed of onboarding.
- **Platform Stability**: Downtime/Incidents of the platform itself.
- **Developer Net Promoter Score (NPS)**.
