# POS (Point of Sale) System

A complete retail POS system with inventory management, sales processing, and reporting.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            POS SYSTEM                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         FRONTEND                                     │    │
│  │  ┌───────────────────┐  ┌───────────────────┐                       │    │
│  │  │    POS Terminal   │  │   Admin Dashboard │                       │    │
│  │  │   (Touch-based)   │  │   (Management)    │                       │    │
│  │  │   - Scan items    │  │   - Inventory     │                       │    │
│  │  │   - Process sales │  │   - Reports       │                       │    │
│  │  │   - Print receipt │  │   - Users         │                       │    │
│  │  └─────────┬─────────┘  └─────────┬─────────┘                       │    │
│  └────────────┼──────────────────────┼──────────────────────────────────┘    │
│               └──────────┬───────────┘                                       │
│                          ▼                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         BACKEND API                                  │    │
│  │                                                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │    │
│  │  │  Sales API  │  │ Inventory   │  │ Products    │  │  Reports    │ │    │
│  │  │             │  │     API     │  │    API      │  │    API      │ │    │
│  │  │ - Checkout  │  │ - Stock     │  │ - CRUD      │  │ - Daily     │ │    │
│  │  │ - Refunds   │  │ - Alerts    │  │ - Categories│  │ - Export    │ │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │    │
│  └─────────────────────────────┬───────────────────────────────────────┘    │
│                                │                                             │
│  ┌─────────────────────────────┼───────────────────────────────────────┐    │
│  │                          DATA LAYER                                  │    │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │    │
│  │  │    PostgreSQL   │  │     Redis       │  │    MinIO        │      │    │
│  │  │   (Main DB)     │  │   (Cache/Queue) │  │   (Receipts)    │      │    │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Sales Processing**: Barcode scanning, cart management, checkout
- **Inventory**: Stock tracking, low stock alerts, auto-reorder
- **Products**: Categories, pricing, discounts, tax rates
- **Reports**: Daily sales, top products, revenue charts
- **Users**: Cashiers, managers, admin roles
- **Receipts**: PDF generation, email, print

## Quick Start

```bash
docker compose up -d

# Access:
# - POS Terminal: http://localhost:3000
# - Admin Dashboard: http://localhost:3001
# - API: http://localhost:8000
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/sales` | Create new sale |
| `GET /api/sales/:id` | Get sale details |
| `POST /api/sales/:id/refund` | Process refund |
| `GET /api/products` | List products |
| `POST /api/products` | Create product |
| `GET /api/inventory` | Get stock levels |
| `POST /api/inventory/adjust` | Adjust stock |
| `GET /api/reports/daily` | Daily sales report |
