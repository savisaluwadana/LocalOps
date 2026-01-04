# Real-Time Chat Application

A scalable real-time chat application with WebSockets.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         REAL-TIME CHAT                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Clients (Browser/Mobile)                                                    │
│       │                                                                      │
│       │ WebSocket                                                            │
│       ▼                                                                      │
│  ┌─────────────────┐         ┌─────────────────┐                            │
│  │  Load Balancer  │────────►│   Redis PubSub  │  (cross-server sync)      │
│  │    (nginx)      │         └─────────────────┘                            │
│  └────────┬────────┘                                                         │
│           │                                                                  │
│  ┌────────┼────────────────────────────────────┐                            │
│  │        │                                     │                            │
│  │        ▼                                     ▼                            │
│  │  ┌───────────┐                        ┌───────────┐                      │
│  │  │  Server 1 │◄──── Redis PubSub ────►│  Server 2 │                      │
│  │  │  (ws)     │                        │  (ws)     │                      │
│  │  └───────────┘                        └───────────┘                      │
│  └──────────────────────────────────────────────────────────────────────────┘
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         DATA LAYER                                   │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │  MongoDB    │  │    Redis    │  │    S3       │                  │    │
│  │  │ (Messages)  │  │(Presence)   │  │ (Files)     │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Real-time Messaging** - WebSocket connections
- **Rooms/Channels** - Group conversations
- **Direct Messages** - Private 1:1 chat
- **Presence** - Online/offline status
- **Typing Indicators** - Real-time feedback
- **File Sharing** - Images, documents
- **Message History** - Paginated retrieval
- **Horizontal Scaling** - Redis PubSub sync

## Quick Start

```bash
docker compose up -d

# Open chat client
open http://localhost:3000
```

## WebSocket Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `message` | Client→Server | Send message |
| `message` | Server→Client | Receive message |
| `join` | Client→Server | Join room |
| `leave` | Client→Server | Leave room |
| `typing` | Bidirectional | Typing indicator |
| `presence` | Server→Client | User online/offline |
