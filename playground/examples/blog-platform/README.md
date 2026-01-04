# Blog Platform

A multi-tenant blog platform with content management.

## Features

- **Multi-tenant**: Multiple blogs per account
- **Content Management**: Posts, pages, categories
- **Media Library**: Image uploads, CDN integration
- **Comments**: Moderation, spam filtering
- **SEO**: Meta tags, sitemaps, structured data
- **Analytics**: Page views, popular posts
- **API-first**: Headless CMS support

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           BLOG PLATFORM                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         FRONTEND                                     │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │   Public    │  │   Admin     │  │   Editor    │                  │    │
│  │  │   Blog      │  │  Dashboard  │  │    (WYSIWYG)│                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                         API                                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │   Posts     │  │   Users     │  │   Media     │  │  Comments   │  │  │
│  │  │   Service   │  │   Service   │  │   Service   │  │   Service   │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                              │                                               │
│  ┌───────────────────────────┼───────────────────────────────────────────┐  │
│  │                       STORAGE                                          │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │  PostgreSQL │  │    Redis    │  │  Minio/S3   │  │Elasticsearch│  │  │
│  │  │  (Content)  │  │   (Cache)   │  │   (Media)   │  │  (Search)   │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
docker compose up -d

# Access:
# - Blog: http://localhost:3000
# - Admin: http://localhost:3000/admin
# - API: http://localhost:8000
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/posts` | List posts |
| `GET /api/posts/:slug` | Get post by slug |
| `POST /api/posts` | Create post (auth) |
| `PUT /api/posts/:id` | Update post (auth) |
| `GET /api/categories` | List categories |
| `GET /api/comments/:postId` | Get comments |
| `POST /api/comments` | Add comment |
| `POST /api/media/upload` | Upload media (auth) |
