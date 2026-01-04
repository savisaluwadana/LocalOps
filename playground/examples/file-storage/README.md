# File Storage Service

A scalable file storage service with CDN support.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FILE STORAGE SERVICE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Client Upload                                                               │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────┐         ┌─────────────────┐                            │
│  │   Upload API    │────────►│     Redis       │ (rate limits, progress)   │
│  │  (multipart)    │         └─────────────────┘                            │
│  └────────┬────────┘                                                         │
│           │                                                                  │
│           │ Chunk & Store                                                    │
│           ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      STORAGE BACKENDS                                │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │    MinIO    │  │     S3      │  │     GCS     │                  │    │
│  │  │  (default)  │  │ (optional)  │  │ (optional)  │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                          CDN LAYER                                   │    │
│  │  ┌─────────────┐  ┌─────────────┐                                   │    │
│  │  │  Cloudflare │  │   nginx     │ (edge caching)                    │    │
│  │  │  (optional) │  │  (default)  │                                   │    │
│  │  └─────────────┘  └─────────────┘                                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multipart Upload** - Large file chunking
- **Resumable Uploads** - Resume interrupted transfers
- **Image Processing** - Resize, crop, watermark
- **CDN Integration** - Edge caching
- **Presigned URLs** - Secure temporary access
- **Virus Scanning** - ClamAV integration
- **Quotas** - Per-user storage limits

## Quick Start

```bash
docker compose up -d

# Upload file
curl -X POST http://localhost:8000/api/upload \
  -F "file=@myimage.jpg"

# Get file
curl http://localhost:8000/files/abc123.jpg
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/upload` | Upload file |
| `POST /api/upload/multipart/init` | Start multipart upload |
| `POST /api/upload/multipart/:id/part` | Upload chunk |
| `POST /api/upload/multipart/:id/complete` | Complete upload |
| `GET /files/:key` | Download file |
| `GET /api/files/:key/presigned` | Get presigned URL |
| `DELETE /api/files/:key` | Delete file |
