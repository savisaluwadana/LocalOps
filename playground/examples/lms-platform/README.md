# Learning Management System (LMS)

Online learning and course platform.

## Features

- **Courses** - Create, publish, enroll
- **Lessons** - Video, text, quizzes
- **Progress** - Tracking, completion
- **Certificates** - Auto-generated on completion
- **Discussions** - Course forums
- **Assignments** - Submission, grading
- **Live Classes** - Video conferencing

## Quick Start

```bash
docker compose up -d

# LMS: http://localhost:3000
# Admin: http://localhost:3000/admin
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/courses` | List courses |
| `POST /api/courses/:id/enroll` | Enroll in course |
| `GET /api/progress/:courseId` | Get progress |
| `POST /api/lessons/:id/complete` | Mark complete |
