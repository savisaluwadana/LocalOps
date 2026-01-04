# CI/CD Complete Theory Guide

## Table of Contents

1. [What is CI/CD?](#what-is-cicd)
2. [Continuous Integration (CI)](#continuous-integration-ci)
3. [Continuous Delivery vs Deployment](#continuous-delivery-vs-deployment)
4. [Pipeline Design](#pipeline-design)
5. [Testing Strategies](#testing-strategies)
6. [Deployment Strategies](#deployment-strategies)
7. [Pipeline Patterns](#pipeline-patterns)
8. [Security in CI/CD](#security-in-cicd)
9. [Best Practices](#best-practices)
10. [Tools Overview](#tools-overview)

---

## What is CI/CD?

### The Before Times

Before CI/CD, software releases looked like this:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TRADITIONAL RELEASE PROCESS                                │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Week 1-4: Developers code features independently                                  │
│   ├── Alice works on feature A                                                      │
│   ├── Bob works on feature B                                                        │
│   └── Charlie works on feature C                                                    │
│                                                                                      │
│   Week 5: "Integration Hell"                                                         │
│   ├── Everyone tries to merge their code                                            │
│   ├── Massive conflicts                                                             │
│   ├── Features don't work together                                                  │
│   └── Blame and frustration                                                         │
│                                                                                      │
│   Week 6-8: Stabilization                                                            │
│   ├── Bug fixing sprint                                                             │
│   ├── QA finds issues                                                               │
│   └── Developers context-switch back to old code                                    │
│                                                                                      │
│   Week 9: Release Day                                                                │
│   ├── Manual deployment scripts                                                     │
│   ├── "Works on my machine"                                                         │
│   ├── Production issues                                                             │
│   └── Weekend firefighting                                                          │
│                                                                                      │
│   Result: Releases are painful, risky, and infrequent                               │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### The CI/CD Way

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           CI/CD PROCESS                                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   EVERY DAY (or multiple times per day):                                            │
│                                                                                      │
│   Developer                                                                          │
│   ├── 1. Writes small change                                                        │
│   ├── 2. Runs tests locally                                                         │
│   └── 3. Pushes to repository                                                       │
│              │                                                                       │
│              ▼                                                                       │
│   CI Pipeline (automatic)                                                            │
│   ├── 4. Builds the code                                                            │
│   ├── 5. Runs all tests                                                             │
│   ├── 6. Scans for vulnerabilities                                                  │
│   └── 7. Reports pass/fail in minutes                                               │
│              │                                                                       │
│              ▼                                                                       │
│   CD Pipeline (automatic)                                                            │
│   ├── 8. Deploys to staging                                                         │
│   ├── 9. Runs integration tests                                                     │
│   └── 10. Deploys to production (or waits for approval)                             │
│                                                                                      │
│   Result: Small, safe, frequent releases                                            │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### The Three Pillars

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                      │
│   CONTINUOUS        CONTINUOUS          CONTINUOUS                                   │
│   INTEGRATION       DELIVERY            DEPLOYMENT                                   │
│                                                                                      │
│   ┌─────────┐       ┌─────────┐         ┌─────────┐                                 │
│   │  Build  │       │  Stage  │         │  Prod   │                                 │
│   │  Test   │──────▶│  Test   │────────▶│ Deploy  │                                 │
│   │  Merge  │       │  Ready  │         │  Auto   │                                 │
│   └─────────┘       └─────────┘         └─────────┘                                 │
│       │                 │                   │                                        │
│       │                 │                   │                                        │
│   Developers       Code is always      Every change                                 │
│   integrate        deployable          goes to prod                                 │
│   frequently                           automatically                                 │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Continuous Integration (CI)

### Definition

**Continuous Integration** is the practice of frequently integrating code changes into a shared repository, followed by automated builds and tests.

### Core Principles

**1. Commit Often**
- Integrate changes at least daily
- Smaller changes are easier to merge
- Problems are found quickly

**2. Every Commit Triggers a Build**
- No manual intervention needed
- Fast feedback (minutes, not hours)
- Broken builds are visible to everyone

**3. Fix Broken Builds Immediately**
- Broken build = team's top priority
- Everyone stops until it's fixed
- Prevents "broken window syndrome"

**4. Keep the Build Fast**
- Target: under 10 minutes
- Fast feedback enables fast fixes
- Slow builds kill productivity

### What CI Looks Like

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           CI PIPELINE FLOW                                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Developer pushes code                                                              │
│          │                                                                           │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │    TRIGGER   │  Webhook notifies CI server                                      │
│   └──────┬───────┘                                                                  │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │   CHECKOUT   │  Clone repository, specific commit                               │
│   └──────┬───────┘                                                                  │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │    BUILD     │  Compile code, install dependencies                              │
│   └──────┬───────┘                                                                  │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │   LINT/SAST  │  Code quality, static analysis                                   │
│   └──────┬───────┘                                                                  │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │  UNIT TESTS  │  Fast, isolated tests                                            │
│   └──────┬───────┘                                                                  │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │  INTEGRATION │  Test components together                                        │
│   │    TESTS     │                                                                  │
│   └──────┬───────┘                                                                  │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │   ARTIFACT   │  Create deployable package                                       │
│   └──────┬───────┘                                                                  │
│          ▼                                                                           │
│   ┌──────────────┐                                                                  │
│   │    NOTIFY    │  Slack, email, GitHub status                                     │
│   └──────────────┘                                                                  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Benefits of CI

| Benefit | Explanation |
|---------|-------------|
| **Early Bug Detection** | Issues found minutes after introduction, not weeks later |
| **Reduced Integration Risk** | Small, frequent merges avoid "integration hell" |
| **Increased Confidence** | Automated tests validate every change |
| **Better Code Quality** | Consistent standards enforced automatically |
| **Faster Development** | Less time debugging, more time building |

---

## Continuous Delivery vs Deployment

### The Key Difference

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                      │
│   CONTINUOUS DELIVERY                    CONTINUOUS DEPLOYMENT                       │
│                                                                                      │
│   Build                                  Build                                       │
│     ↓                                      ↓                                         │
│   Test                                   Test                                        │
│     ↓                                      ↓                                         │
│   Stage                                  Stage                                       │
│     ↓                                      ↓                                         │
│   ┌─────────────┐                        Production                                 │
│   │   MANUAL    │                        (automatic!)                               │
│   │  APPROVAL   │                                                                   │
│   └──────┬──────┘                                                                   │
│          ↓                                                                           │
│   Production                                                                         │
│                                                                                      │
│   "Could deploy at any time"             "Does deploy every time"                   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Continuous Delivery

**Definition:** Every change is automatically tested and prepared for release to production, but deployment requires manual approval.

**When to use:**
- Regulatory requirements need human sign-off
- Business wants control over release timing
- High-risk or complex deployments
- Teams new to automation

**Process:**
1. Developer pushes code
2. Automated tests run
3. Code deployed to staging
4. Automated acceptance tests
5. ✋ Human clicks "Deploy to Production"
6. Production deployment

### Continuous Deployment

**Definition:** Every change that passes all tests is automatically deployed to production.

**When to use:**
- High confidence in test coverage
- Mature DevOps culture
- Need for rapid iteration
- Consumer-facing products with fast feedback loops

**Requirements:**
- Comprehensive automated testing
- Feature flags for releasing features separately
- Robust monitoring and alerting
- Quick rollback capabilities

---

## Pipeline Design

### Anatomy of a Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           COMPLETE CI/CD PIPELINE                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                              STAGE 1: BUILD                                  │   │
│   │  • Compile source code          • Install dependencies                      │   │
│   │  • Generate artifacts           • Create Docker images                      │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         │                                            │
│                                         ▼                                            │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                              STAGE 2: TEST                                   │   │
│   │  • Unit tests                   • Integration tests                         │   │
│   │  • Code coverage                • Performance tests                         │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         │                                            │
│                                         ▼                                            │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                            STAGE 3: SECURITY                                 │   │
│   │  • SAST (static analysis)       • Dependency scanning                       │   │
│   │  • Secret detection             • Container scanning                        │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         │                                            │
│                                         ▼                                            │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                           STAGE 4: STAGING                                   │   │
│   │  • Deploy to staging            • Smoke tests                               │   │
│   │  • E2E tests                    • Acceptance tests                          │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         │                                            │
│                                         ▼                                            │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                          STAGE 5: PRODUCTION                                 │   │
│   │  • Manual approval (optional)   • Canary deployment                         │   │
│   │  • Rolling update               • Post-deploy verification                  │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Pipeline Stages Explained

**Stage 1: Build**

This stage compiles code and creates deployable artifacts.

| Task | Purpose |
|------|---------|
| Checkout code | Get the source code |
| Install dependencies | npm install, pip install, etc. |
| Compile | Transform source to executable |
| Create artifact | JAR, Docker image, binary |
| Push artifact | Store for later stages |

**Stage 2: Test**

Validate that code works correctly.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TESTING PYRAMID                                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│                           /\                                                         │
│                          /  \         E2E Tests                                     │
│                         /    \        (Few, Slow, Expensive)                        │
│                        /──────\                                                      │
│                       /        \      Integration Tests                             │
│                      /          \     (Some, Medium Speed)                          │
│                     /────────────\                                                   │
│                    /              \   Unit Tests                                    │
│                   /                \  (Many, Fast, Cheap)                           │
│                  /══════════════════\                                               │
│                                                                                      │
│   Write MORE tests at the bottom, FEWER at the top                                  │
│                                                                                      │
│   Unit Tests:        70% of tests, run in milliseconds, no dependencies            │
│   Integration Tests: 20% of tests, test component interactions                     │
│   E2E Tests:         10% of tests, test entire user flows                          │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Stage 3: Security**

Find vulnerabilities before they reach production.

| Scan Type | What It Checks | Examples |
|-----------|----------------|----------|
| SAST | Source code for vulnerabilities | SonarQube, CodeQL, Semgrep |
| SCA | Dependencies for known CVEs | Snyk, Dependabot, OWASP Dependency-Check |
| DAST | Running application | OWASP ZAP, Burp Suite |
| Container Scan | Docker images for CVEs | Trivy, Grype, Clair |
| Secret Detection | Hardcoded secrets | GitLeaks, TruffleHog |

**Stage 4: Staging**

Test in a production-like environment.

- Deploy to staging environment
- Run smoke tests (basic functionality)
- Run E2E tests (full user journeys)
- Performance testing
- UAT (User Acceptance Testing)

**Stage 5: Production**

Deploy to real users.

- Approval gates (optional)
- Progressive rollout
- Health checks
- Rollback capability
- Post-deployment verification

---

## Testing Strategies

### Test Types Explained

**Unit Tests**

Test individual functions or methods in isolation.

```python
# Example unit test
def test_calculate_discount():
    # Given
    original_price = 100
    discount_percent = 20
    
    # When
    result = calculate_discount(original_price, discount_percent)
    
    # Then
    assert result == 80
```

**Characteristics:**
- Fast (milliseconds)
- No external dependencies
- Mock everything external
- Run on every commit

**Integration Tests**

Test how components work together.

```python
# Example integration test
def test_user_registration():
    # Given - real database connection
    user_data = {"email": "test@example.com", "password": "secret"}
    
    # When - actual service call
    response = user_service.register(user_data)
    
    # Then - verify database
    user = database.find_user_by_email("test@example.com")
    assert user is not None
    assert response.status == 201
```

**Characteristics:**
- Medium speed (seconds)
- Uses real databases (often in containers)
- Tests component boundaries
- Run on every commit or PR

**End-to-End (E2E) Tests**

Test complete user journeys through the system.

```javascript
// Example E2E test with Playwright
test('user can complete checkout', async ({ page }) => {
  // Login
  await page.goto('/login');
  await page.fill('#email', 'user@example.com');
  await page.fill('#password', 'password');
  await page.click('button[type="submit"]');
  
  // Add item to cart
  await page.goto('/products');
  await page.click('.add-to-cart');
  
  // Checkout
  await page.goto('/checkout');
  await page.click('#confirm-order');
  
  // Verify
  await expect(page.locator('.order-confirmation')).toBeVisible();
});
```

**Characteristics:**
- Slow (minutes)
- Tests entire user flows
- Brittle (break easily)
- Run less frequently (staging/pre-prod)

### Test Best Practices

| Practice | Why |
|----------|-----|
| Test behavior, not implementation | Tests survive refactoring |
| Use meaningful test names | Self-documenting tests |
| One assertion per test | Clear failure messages |
| Arrange-Act-Assert pattern | Readable test structure |
| Independent tests | Can run in any order |
| Fast tests | Developers run them often |

---

## Deployment Strategies

### Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DEPLOYMENT STRATEGIES                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   RECREATE                                                                           │
│   ┌─────────┐         ┌─────────┐                                                   │
│   │  v1.0   │ ──────▶ │  v2.0   │  Stop all old, start all new                     │
│   │   ███   │         │   ███   │  Downtime: YES                                    │
│   └─────────┘         └─────────┘  Risk: HIGH                                       │
│                                                                                      │
│   ROLLING UPDATE                                                                     │
│   ┌─────────┐         ┌─────────┐         ┌─────────┐         ┌─────────┐          │
│   │ v1 v1   │ ──────▶ │ v1 v2   │ ──────▶ │ v2 v2   │ ──────▶ │ v2 v2   │          │
│   │ v1 v1   │         │ v1 v1   │         │ v1 v2   │         │ v2 v2   │          │
│   └─────────┘         └─────────┘         └─────────┘         └─────────┘          │
│   Replace one at a time                   Downtime: NO    Risk: LOW                 │
│                                                                                      │
│   BLUE-GREEN                                                                         │
│   ┌─────────┐         ┌─────────┐         ┌─────────┐                               │
│   │  BLUE   │ ──────▶ │  BLUE   │ ──────▶ │  GREEN  │  Two identical environments  │
│   │  v1.0   │         │  v1.0   │         │   v2.0  │  Instant switch               │
│   │  (live) │         │ (green) │         │  (live) │  Easy rollback               │
│   └─────────┘         └─────────┘         └─────────┘                               │
│                        Deploy v2.0         Switch traffic                           │
│                        to green                                                     │
│                                                                                      │
│   CANARY                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                                                                              │   │
│   │   Traffic ────┬──────────────────────────────────────▶ v1.0 (95%)           │   │
│   │               │                                                              │   │
│   │               └──────────────────────────────────────▶ v2.0 (5%)  ← Canary  │   │
│   │                                                                              │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│   Gradually shift traffic if canary is healthy                                      │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Strategy Comparison

| Strategy | Downtime | Rollback | Resource Cost | Risk | Best For |
|----------|----------|----------|---------------|------|----------|
| **Recreate** | Yes | Slow | Low | High | Dev/Test |
| **Rolling** | No | Medium | Low | Medium | Default |
| **Blue-Green** | No | Instant | 2x | Low | Critical apps |
| **Canary** | No | Fast | 1.x | Very Low | Large scale |

### Blue-Green Deployment Explained

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           BLUE-GREEN DEPLOYMENT FLOW                                 │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   STEP 1: Initial state (Blue is live)                                              │
│                                                                                      │
│    Users ────────▶ Load Balancer ────────▶ BLUE (v1.0) ✓                            │
│                               │                                                     │
│                               └────────▶ GREEN (idle)                               │
│                                                                                      │
│   STEP 2: Deploy new version to Green                                               │
│                                                                                      │
│    Users ────────▶ Load Balancer ────────▶ BLUE (v1.0) ✓                            │
│                               │                                                     │
│                               └────────▶ GREEN (v2.0) ← Deploy & test              │
│                                                                                      │
│   STEP 3: Switch traffic to Green                                                   │
│                                                                                      │
│    Users ────────▶ Load Balancer ────────▶ BLUE (v1.0)                              │
│                               │                                                     │
│                               └────────▶ GREEN (v2.0) ✓ ← Now live                 │
│                                                                                      │
│   STEP 4: Blue becomes standby (ready for rollback)                                 │
│                                                                                      │
│   If anything goes wrong: switch back to Blue instantly!                            │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Canary Deployment Explained

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           CANARY DEPLOYMENT PROGRESSION                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Phase 1: Initial Canary (1% traffic)                                              │
│   ├── Monitor for 10 minutes                                                        │
│   ├── Watch: error rates, latency, logs                                            │
│   └── Gate: error rate < 0.1%                                                       │
│                                                                                      │
│   Phase 2: Expand Canary (10% traffic)                                              │
│   ├── Monitor for 30 minutes                                                        │
│   ├── Watch: error rates, latency, resource usage                                  │
│   └── Gate: error rate < 0.5%, latency p99 < 200ms                                 │
│                                                                                      │
│   Phase 3: Partial Rollout (50% traffic)                                            │
│   ├── Monitor for 1 hour                                                            │
│   ├── Watch: business metrics, customer complaints                                 │
│   └── Gate: All previous + no customer complaints                                  │
│                                                                                      │
│   Phase 4: Full Rollout (100% traffic)                                              │
│   ├── Continue monitoring                                                           │
│   └── Keep old version ready for quick rollback                                    │
│                                                                                      │
│   At ANY phase: If gates fail → Automatic rollback                                  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Pipeline Patterns

### Trunk-Based Development

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TRUNK-BASED DEVELOPMENT                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Main/Trunk ────●────●────●────●────●────●────●────●─────▶                         │
│                  ↑    ↑    ↑    ↑    ↑    ↑    ↑    ↑                               │
│                  └────┴────┴────┴────┴────┴────┴────┘                               │
│                  Short-lived branches (< 1 day)                                     │
│                                                                                      │
│   Rules:                                                                             │
│   • All developers commit to main frequently (daily)                                │
│   • Feature branches live less than 1-2 days                                        │
│   • Use feature flags to hide incomplete features                                   │
│   • Main is always deployable                                                       │
│                                                                                      │
│   Benefits:                                                                          │
│   ✓ Reduced merge conflicts                                                         │
│   ✓ Faster integration feedback                                                     │
│   ✓ Simpler branching model                                                         │
│   ✓ Enables continuous deployment                                                   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### GitFlow

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           GITFLOW BRANCHING                                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   main      ────●─────────────────●───────────────────●────▶  (releases)            │
│                  ╲               ╱                   ╱                               │
│   develop  ──────●──●──●──●──●──●──●──●──●──●──●──●──▶  (integration)               │
│                     ╲   ╱   ╲   ╱       ╲   ╱                                        │
│   feature/      ────●──●     ●──●        ●──●──▶  (development)                     │
│                                                                                      │
│   Branches:                                                                          │
│   • main:     Production code, tagged releases                                      │
│   • develop:  Integration branch, next release                                      │
│   • feature/: New features (from develop)                                           │
│   • release/: Release preparation                                                   │
│   • hotfix/:  Emergency production fixes                                            │
│                                                                                      │
│   Best for:                                                                          │
│   • Scheduled releases                                                               │
│   • Multiple supported versions                                                     │
│   • Longer feature development                                                      │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Feature Flags

Feature flags decouple deployment from release:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           FEATURE FLAGS                                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Without Feature Flags:                                                             │
│                                                                                      │
│   Code deployed = Feature released                                                  │
│   (All or nothing, risky)                                                           │
│                                                                                      │
│   With Feature Flags:                                                                │
│                                                                                      │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   if (featureFlags.isEnabled("new_checkout"))  {                             │   │
│   │       return newCheckoutFlow();                                              │   │
│   │   } else {                                                                   │   │
│   │       return oldCheckoutFlow();                                              │   │
│   │   }                                                                          │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   Deployment:  Code is in production but hidden                                     │
│   Release:     Flip the flag to enable the feature                                  │
│                                                                                      │
│   Benefits:                                                                          │
│   ✓ Deploy incomplete features safely                                               │
│   ✓ Gradual rollouts (1% → 10% → 50% → 100%)                                       │
│   ✓ A/B testing built-in                                                            │
│   ✓ Kill switch for broken features                                                │
│   ✓ Beta testing with specific users                                               │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Security in CI/CD

### Shift Left Security

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           SHIFT LEFT SECURITY                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Traditional: Find bugs in production (expensive, dangerous)                       │
│                                                                                      │
│   Development    Build    Test    Stage    Production                               │
│       │          │        │        │          ▲                                     │
│       │          │        │        │          │                                     │
│       │          │        │        │     ┌────┴────┐                               │
│       │          │        │        │     │ Find    │                               │
│       │          │        │        │     │ Vuln    │  ← Too late!                  │
│       │          │        │        │     └─────────┘                               │
│                                                                                      │
│   Shift Left: Find bugs early (cheap, safe)                                         │
│                                                                                      │
│   Development    Build    Test    Stage    Production                               │
│       ▲            ▲       ▲                                                        │
│   ┌───┴───┐    ┌───┴───┐  ┌┴┐                                                      │
│   │Pre-   │    │SAST   │  │D│                                                      │
│   │commit │    │SCA    │  │A│                                                      │
│   │hooks  │    │IaC    │  │S│                                                      │
│   └───────┘    └───────┘  │T│                                                      │
│                           └─┘                                                       │
│   Earlier = Cheaper to fix                                                          │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Security Scanning Types

| Scan | When | What | Tools |
|------|------|------|-------|
| **Pre-commit** | Before commit | Secrets, hooks | GitLeaks, Husky |
| **SAST** | Build | Source code | SonarQube, Semgrep |
| **SCA** | Build | Dependencies | Snyk, Dependabot |
| **Container** | Build | Docker images | Trivy, Grype |
| **IaC** | Build | Terraform, K8s | Checkov, tfsec |
| **DAST** | Test/Stage | Running app | OWASP ZAP |
| **IAST** | Test | Runtime analysis | Contrast |

### Pipeline Security Best Practices

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           SECURE PIPELINE PRACTICES                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   SECRETS MANAGEMENT                                                                 │
│   ├── Never store secrets in code                                                   │
│   ├── Use vault (HashiCorp Vault, AWS Secrets Manager)                              │
│   ├── Inject secrets at runtime                                                     │
│   └── Rotate secrets regularly                                                      │
│                                                                                      │
│   LEAST PRIVILEGE                                                                    │
│   ├── Pipeline runners have minimal permissions                                     │
│   ├── Separate credentials per environment                                          │
│   └── Time-limited access tokens                                                    │
│                                                                                      │
│   ARTIFACT SECURITY                                                                  │
│   ├── Sign artifacts cryptographically                                              │
│   ├── Verify signatures before deployment                                           │
│   ├── Use private registries                                                        │
│   └── Generate SBOM (Software Bill of Materials)                                    │
│                                                                                      │
│   AUDIT TRAIL                                                                        │
│   ├── Log all pipeline actions                                                      │
│   ├── Who triggered what, when                                                      │
│   ├── Immutable logs                                                                │
│   └── Regular access reviews                                                        │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Best Practices

### Pipeline Best Practices

| Practice | Why |
|----------|-----|
| **Keep pipelines fast** | Developers need quick feedback |
| **Make pipelines reproducible** | Same input = same output |
| **Fail fast** | Run quick tests first |
| **Don't deploy what you don't test** | Tests are gatekeepers |
| **Version your pipeline config** | Infrastructure as code |
| **Parallelize where possible** | Reduce total run time |
| **Cache dependencies** | Speed up builds |
| **Clean up old artifacts** | Save storage costs |

### When Things Go Wrong

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           HANDLING PIPELINE FAILURES                                 │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Build Failure:                                                                     │
│   ├── Notify immediately (Slack, email)                                             │
│   ├── Block merges until fixed                                                      │
│   └── Assign to last committer                                                      │
│                                                                                      │
│   Test Failure:                                                                      │
│   ├── Is it flaky? (Passes on retry)                                               │
│   │   └── Fix the flaky test ASAP                                                  │
│   └── Is it real? (New bug introduced)                                             │
│       └── Fix the code or revert                                                   │
│                                                                                      │
│   Deployment Failure:                                                                │
│   ├── Automatic rollback if possible                                               │
│   ├── Alert on-call engineer                                                        │
│   └── Post-incident review                                                          │
│                                                                                      │
│   Key metrics to track:                                                              │
│   • Build success rate (target: >95%)                                               │
│   • Mean time to recovery (target: <1 hour)                                         │
│   • Deployment frequency                                                            │
│   • Change failure rate                                                              │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Tools Overview

### CI/CD Platforms

| Tool | Type | Best For |
|------|------|----------|
| **GitHub Actions** | Cloud | GitHub projects, open source |
| **GitLab CI** | Cloud/Self-hosted | GitLab ecosystem |
| **Jenkins** | Self-hosted | Flexibility, plugins |
| **CircleCI** | Cloud | Fast setup, Docker |
| **Azure DevOps** | Cloud | Microsoft ecosystem |
| **ArgoCD** | Self-hosted | Kubernetes GitOps |

### Choosing a Tool

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TOOL SELECTION CRITERIA                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Where is your code?                                                                │
│   ├── GitHub → GitHub Actions                                                        │
│   ├── GitLab → GitLab CI                                                             │
│   └── Azure Repos → Azure Pipelines                                                 │
│                                                                                      │
│   Cloud or self-hosted?                                                              │
│   ├── Cloud (SaaS) → Less maintenance, pay per use                                  │
│   └── Self-hosted → More control, security requirements                            │
│                                                                                      │
│   Team size?                                                                         │
│   ├── Small team → Simple tools (GitHub Actions, CircleCI)                          │
│   └── Enterprise → Feature-rich (Jenkins, GitLab, Azure DevOps)                    │
│                                                                                      │
│   Kubernetes-native?                                                                 │
│   └── Yes → ArgoCD, Flux, Tekton                                                    │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

This comprehensive guide covers CI/CD from fundamentals to advanced practices with detailed explanations and real-world examples.
