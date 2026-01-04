# Tracing Service

Distributed tracing with Jaeger.

## Features

- **Trace Propagation** - Context across services
- **Span Collection** - Timing and metadata
- **Visualization** - Trace timeline view
- **Service Map** - Dependency graph
- **Search** - Find traces by tag/duration

## Quick Start

```bash
docker compose up -d

# Jaeger UI: http://localhost:16686
# App with tracing: http://localhost:8000
```

## Instrumentation

```javascript
const { trace } = require('@opentelemetry/api');
const tracer = trace.getTracer('my-service');

const span = tracer.startSpan('my-operation');
// ... do work
span.end();
```
