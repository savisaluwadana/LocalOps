# Payment Gateway Integration

A payment processing service with Stripe and PayPal integration.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PAYMENT GATEWAY                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Client Checkout                                                             │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────┐         ┌─────────────────┐                            │
│  │  Payment API    │────────►│   PostgreSQL    │ (transactions)            │
│  │                 │         └─────────────────┘                            │
│  └────────┬────────┘                                                         │
│           │                                                                  │
│           │ Route to Provider                                                │
│           ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    PAYMENT PROVIDERS                                 │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │   Stripe    │  │   PayPal    │  │   Square    │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              │ Webhooks                                      │
│                              ▼                                               │
│  ┌─────────────────┐         ┌─────────────────┐                            │
│  │  Webhook Handler│────────►│    RabbitMQ     │ (async processing)        │
│  └─────────────────┘         └─────────────────┘                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multiple Providers** - Stripe, PayPal, Square
- **Payment Methods** - Cards, wallets, bank transfer
- **Subscriptions** - Recurring billing
- **Refunds** - Full/partial refunds
- **Webhooks** - Real-time status updates
- **PCI Compliance** - Tokenization
- **Fraud Detection** - Risk scoring
- **Idempotency** - Safe retries

## Quick Start

```bash
docker compose up -d

# Create payment intent (Stripe)
curl -X POST http://localhost:8000/api/payments/intent \
  -H "Content-Type: application/json" \
  -d '{"amount": 2999, "currency": "usd"}'

# Process payment
curl -X POST http://localhost:8000/api/payments/charge \
  -H "Content-Type: application/json" \
  -d '{"payment_intent_id": "pi_xxx", "payment_method_id": "pm_xxx"}'
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/payments/intent` | Create payment intent |
| `POST /api/payments/charge` | Charge payment method |
| `POST /api/payments/refund` | Process refund |
| `POST /api/subscriptions` | Create subscription |
| `POST /webhooks/stripe` | Stripe webhook handler |
