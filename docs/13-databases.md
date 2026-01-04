# Database Management

This guide covers setting up and managing databases in your local DevOps environment.

---

## PostgreSQL Setup

### Docker Compose

Create `playground/databases/docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secretpassword
      POSTGRES_DB: devops_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@local.com
      PGADMIN_DEFAULT_PASSWORD: admin123
    ports:
      - "5050:80"
    depends_on:
      - postgres
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: devops_db
      MYSQL_USER: admin
      MYSQL_PASSWORD: secretpassword
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    restart: unless-stopped

  redis:
    image: redis:alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  mysql_data:
  redis_data:
```

### Initialize Script

Create `playground/databases/init.sql`:

```sql
-- Create sample tables
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS deployments (
    id SERIAL PRIMARY KEY,
    app_name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    environment VARCHAR(20) NOT NULL,
    deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deployed_by INTEGER REFERENCES users(id)
);

-- Insert sample data
INSERT INTO users (username, email) VALUES 
    ('admin', 'admin@local.com'),
    ('developer', 'dev@local.com');
```

---

## Connection Examples

### From Command Line

```bash
# PostgreSQL
psql -h localhost -U admin -d devops_db

# MySQL
mysql -h localhost -u admin -p devops_db

# Redis
redis-cli -h localhost
```

### From Python

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="devops_db",
    user="admin",
    password="secretpassword"
)
```

### From Ansible

```yaml
- name: Create database user
  postgresql_user:
    name: myapp
    password: mypassword
    db: devops_db
    host: localhost
    login_user: admin
    login_password: secretpassword
```

---

## Backup & Restore

### PostgreSQL

```bash
# Backup
docker exec postgres pg_dump -U admin devops_db > backup.sql

# Restore
cat backup.sql | docker exec -i postgres psql -U admin devops_db
```

### MySQL

```bash
# Backup
docker exec mysql mysqldump -u admin -psecretpassword devops_db > backup.sql

# Restore
cat backup.sql | docker exec -i mysql mysql -u admin -psecretpassword devops_db
```
