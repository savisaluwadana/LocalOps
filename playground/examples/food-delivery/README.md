# Food Delivery Platform

Complete food ordering and delivery system.

## Features

- **Restaurants** - Menu management, hours
- **Orders** - Cart, checkout, payment
- **Delivery** - Driver tracking, routing
- **Customers** - Profiles, favorites, history
- **Real-time** - Order status updates
- **Reviews** - Ratings, feedback
- **Admin** - Restaurant dashboard

## Quick Start

```bash
docker compose up -d

# Customer App: http://localhost:3000
# Restaurant Dashboard: http://localhost:3001
# Driver App: http://localhost:3002
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/restaurants` | List restaurants |
| `GET /api/restaurants/:id/menu` | Get menu |
| `POST /api/orders` | Create order |
| `GET /api/orders/:id/track` | Track delivery |
