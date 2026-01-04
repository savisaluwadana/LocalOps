# Microservices Architecture Example

A complete microservices application demonstrating service discovery, API gateway, and inter-service communication.

## Architecture

```
                    ┌─────────────────┐
                    │   API Gateway   │
                    │   (nginx)       │
                    │   :8080         │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  User Service   │ │ Product Service │ │  Order Service  │
│     :3001       │ │     :3002       │ │     :3003       │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         ▼                   ▼                   ▼
   ┌───────────┐       ┌───────────┐       ┌───────────┐
   │  MongoDB  │       │  MongoDB  │       │  MongoDB  │
   │   users   │       │  products │       │  orders   │
   └───────────┘       └───────────┘       └───────────┘
```

## Quick Start

```bash
docker compose up -d

# API Gateway: http://localhost:8080
# - /api/users    -> User Service
# - /api/products -> Product Service
# - /api/orders   -> Order Service
```

## Services

### User Service
- `GET /users` - List users
- `POST /users` - Create user
- `GET /users/:id` - Get user

### Product Service
- `GET /products` - List products
- `POST /products` - Create product
- `GET /products/:id` - Get product

### Order Service
- `GET /orders` - List orders
- `POST /orders` - Create order (calls User & Product services)
- `GET /orders/:id` - Get order with details
