# E-Commerce Platform

A complete e-commerce application with microservices architecture, CI/CD, and Kubernetes deployment.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         E-COMMERCE PLATFORM                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                            CLIENT LAYER                              │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │   Web App   │  │  Mobile App │  │  Admin Panel│                  │    │
│  │  │   (React)   │  │  (Flutter)  │  │   (React)   │                  │    │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │    │
│  └─────────┼────────────────┼────────────────┼──────────────────────────┘    │
│            └────────────────┼────────────────┘                               │
│                             ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                          API GATEWAY                                 │    │
│  │                         (Kong / Nginx)                               │    │
│  │              Rate Limiting | Auth | Load Balancing                   │    │
│  └───────────────────────────┬─────────────────────────────────────────┘    │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                      MICROSERVICES                                     │  │
│  │                                                                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │   Product   │  │    Order    │  │    User     │  │   Payment   │  │  │
│  │  │   Service   │  │   Service   │  │   Service   │  │   Service   │  │  │
│  │  │   :3001     │  │   :3002     │  │   :3003     │  │   :3004     │  │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │  │
│  │         │                │                │                │          │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │  Inventory  │  │   Shipping  │  │Notification │  │   Search    │  │  │
│  │  │   Service   │  │   Service   │  │   Service   │  │   Service   │  │  │
│  │  │   :3005     │  │   :3006     │  │   :3007     │  │   :3008     │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                      DATA LAYER                                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │  PostgreSQL │  │    Redis    │  │Elasticsearch│  │  RabbitMQ   │  │  │
│  │  │  (Products) │  │   (Cache)   │  │  (Search)   │  │  (Events)   │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Start all services
docker compose up -d

# Access:
# - API Gateway: http://localhost:8000
# - Admin: http://localhost:3000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3001
```

## API Endpoints

| Service | Endpoints |
|---------|-----------|
| Products | `GET /api/products`, `POST /api/products`, `GET /api/products/:id` |
| Orders | `GET /api/orders`, `POST /api/orders`, `PUT /api/orders/:id/status` |
| Users | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/users/me` |
| Cart | `GET /api/cart`, `POST /api/cart/items`, `DELETE /api/cart/items/:id` |
| Payments | `POST /api/payments/checkout`, `GET /api/payments/:id` |
