# Booking/Reservation System

A complete booking system for appointments, hotels, or events.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BOOKING SYSTEM                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     CLIENT APPLICATIONS                              │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │  Customer   │  │   Admin     │  │   Mobile    │                  │    │
│  │  │   Portal    │  │  Dashboard  │  │    App      │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └───────────────────────────┬─────────────────────────────────────────┘    │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                      BOOKING API                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │   Slots     │  │  Bookings   │  │   Users     │  │   Notify    │  │  │
│  │  │   Service   │  │   Service   │  │   Service   │  │   Service   │  │  │
│  │  │ - Available │  │ - Create    │  │ - Auth      │  │ - Email     │  │  │
│  │  │ - Reserve   │  │ - Cancel    │  │ - Profile   │  │ - SMS       │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                       DATA LAYER                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                    │  │
│  │  │  PostgreSQL │  │    Redis    │  │  RabbitMQ   │                    │  │
│  │  │ (Bookings)  │  │   (Locks)   │  │  (Events)   │                    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                    │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Slot Management** - Available times, capacity
- **Double-Booking Prevention** - Redis distributed locks
- **Booking CRUD** - Create, cancel, reschedule
- **Notifications** - Email/SMS reminders
- **Calendar Sync** - Google Calendar, iCal
- **Payment Integration** - Stripe deposits
- **Waitlist** - Auto-notify on cancellation

## Quick Start

```bash
docker compose up -d

# Create a slot
curl -X POST http://localhost:8000/api/slots \
  -H "Content-Type: application/json" \
  -d '{"date": "2024-01-15", "start_time": "09:00", "end_time": "10:00", "capacity": 1}'

# Book a slot
curl -X POST http://localhost:8000/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"slot_id": 1, "customer_name": "John", "customer_email": "john@example.com"}'
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/slots` | List available slots |
| `POST /api/slots` | Create slot (admin) |
| `POST /api/bookings` | Create booking |
| `GET /api/bookings/:id` | Get booking details |
| `DELETE /api/bookings/:id` | Cancel booking |
| `PUT /api/bookings/:id/reschedule` | Reschedule |
