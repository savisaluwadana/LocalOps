# Authentication Service

A complete identity and access management service.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      AUTHENTICATION SERVICE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Applications                                                                │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         AUTH API                                     │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │    │
│  │  │   Login     │  │  Register   │  │   OAuth     │  │    MFA      │ │    │
│  │  │             │  │             │  │ (Google,    │  │  (TOTP,     │ │    │
│  │  │             │  │             │  │  GitHub)    │  │   SMS)      │ │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                       TOKEN MANAGEMENT                                 │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                    │  │
│  │  │    JWT      │  │   Refresh   │  │   Session   │                    │  │
│  │  │  (Access)   │  │   Tokens    │  │   Store     │                    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                    │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                       DATA LAYER                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐                                     │  │
│  │  │  PostgreSQL │  │    Redis    │                                     │  │
│  │  │   (Users)   │  │  (Sessions) │                                     │  │
│  │  └─────────────┘  └─────────────┘                                     │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Local Auth** - Email/password login
- **OAuth 2.0** - Google, GitHub, Facebook
- **MFA/2FA** - TOTP, SMS, Email
- **JWT Tokens** - Access + refresh tokens
- **Session Management** - Redis-backed sessions
- **Password Reset** - Secure token flow
- **Rate Limiting** - Brute force protection
- **Audit Logging** - Login history

## Quick Start

```bash
docker compose up -d

# Register
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@test.com", "password": "secure123", "name": "John"}'

# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@test.com", "password": "secure123"}'
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/auth/register` | Register user |
| `POST /api/auth/login` | Login |
| `POST /api/auth/logout` | Logout |
| `POST /api/auth/refresh` | Refresh access token |
| `POST /api/auth/forgot-password` | Request password reset |
| `POST /api/auth/reset-password` | Reset password |
| `GET /api/auth/oauth/google` | Google OAuth |
| `POST /api/auth/mfa/enable` | Enable MFA |
| `POST /api/auth/mfa/verify` | Verify MFA code |
