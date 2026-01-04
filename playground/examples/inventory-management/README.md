# Inventory Management System

A complete inventory and warehouse management system.

## Features

- **Product Management**: SKU, variants, categories
- **Stock Tracking**: Real-time inventory levels
- **Warehouse Management**: Multiple locations
- **Purchase Orders**: Supplier management, ordering
- **Stock Alerts**: Low stock notifications
- **Audit Trail**: Track all inventory changes
- **Barcode Support**: Scanning and generation
- **Reports**: Stock valuation, movement, turnover

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     INVENTORY MANAGEMENT SYSTEM                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                          DASHBOARD                                   │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │   Stock     │  │  Warehouse  │  │   Reports   │                  │    │
│  │  │   Levels    │  │    View     │  │   Charts    │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                        SERVICES                                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │  Products   │  │   Stock     │  │  Warehouse  │  │  Purchase   │  │  │
│  │  │   Service   │  │  Service    │  │   Service   │  │   Orders    │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │  Suppliers  │  │  Shipments  │  │  Barcode    │  │   Alerts    │  │  │
│  │  │   Service   │  │  Service    │  │   Service   │  │   Service   │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
docker compose up -d

# Access:
# - Dashboard: http://localhost:3000
# - API: http://localhost:8000
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/products` | List products |
| `GET /api/stock` | Current stock levels |
| `POST /api/stock/adjust` | Adjust stock quantity |
| `POST /api/stock/transfer` | Transfer between warehouses |
| `GET /api/warehouses` | List warehouses |
| `POST /api/purchase-orders` | Create purchase order |
| `GET /api/alerts` | Low stock alerts |
| `GET /api/reports/valuation` | Stock valuation report |
