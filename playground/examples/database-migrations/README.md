# Database Migrations

Managing database schema changes with version control.

## Tools Used

- **Flyway** - SQL-based migrations
- **Prisma** - ORM with migrations
- **golang-migrate** - CLI tool

## Quick Start

```bash
# Start database and run migrations
docker compose up -d

# Check migration status
docker compose exec flyway flyway info

# Run new migration
docker compose exec flyway flyway migrate
```

## Migration Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      DATABASE MIGRATION WORKFLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Developer                CI/CD                  Production                  │
│      │                      │                        │                       │
│      │  1. Write migration  │                        │                       │
│      ├─────────────────────►│                        │                       │
│      │     V001_create_     │  2. Test in           │                       │
│      │     users.sql        │     staging           │                       │
│      │                      ├────────────────────────┤                       │
│      │                      │  3. Apply to prod     │                       │
│      │                      ├───────────────────────►│                       │
│      │                      │                        │                       │
│      │                      │  4. Verify             │                       │
│      │◄─────────────────────┼────────────────────────┤                       │
│      │                      │                        │                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Best Practices

1. **Migrations are immutable** - Never edit applied migrations
2. **One migration = one change** - Keep them atomic
3. **Test rollbacks** - Always have a down migration
4. **Use transactions** - Wrap DDL in transactions
5. **Backup first** - Always backup before running in prod
