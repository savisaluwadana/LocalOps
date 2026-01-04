# Feature Flags

Control feature rollouts without code deployments.

## Benefits

- **Gradual Rollout** - Release to 1% → 10% → 100%
- **A/B Testing** - Compare feature versions
- **Kill Switch** - Instantly disable broken features
- **User Targeting** - Enable for specific users/groups

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Application   │────►│  Feature Flag   │
│                 │     │     Service     │
└─────────────────┘     └─────────────────┘
         │                      │
         │ if (isEnabled)       │ Rules:
         │   showNewFeature()   │ - 10% users
         │ else                 │ - beta group
         │   showOldFeature()   │ - env=staging
```

## Quick Start

```bash
docker compose up -d

# Access Unleash UI
open http://localhost:4242
# Login: admin / unleash4all

# Create a flag via API
curl -X POST http://localhost:4242/api/admin/projects/default/features \
    -H "Authorization: *:development.unleash-insecure-api-token" \
    -H "Content-Type: application/json" \
    -d '{"name": "new-checkout", "type": "release"}'
```

## SDK Usage

```javascript
const { initialize } = require('unleash-client');

const unleash = initialize({
    url: 'http://localhost:4242/api',
    appName: 'my-app',
    customHeaders: { Authorization: 'token' }
});

if (unleash.isEnabled('new-checkout')) {
    showNewCheckout();
} else {
    showOldCheckout();
}
```
