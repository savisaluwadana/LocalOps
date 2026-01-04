-- Helpdesk Schema

CREATE TABLE agents (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'agent',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tickets (
    id SERIAL PRIMARY KEY,
    ticket_number VARCHAR(20) UNIQUE NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'open',
    priority VARCHAR(20) DEFAULT 'medium',
    category VARCHAR(100),
    customer_email VARCHAR(255),
    customer_name VARCHAR(100),
    assigned_to INTEGER REFERENCES agents(id),
    resolution TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE TABLE ticket_comments (
    id SERIAL PRIMARY KEY,
    ticket_id INTEGER REFERENCES tickets(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    author_id INTEGER REFERENCES agents(id),
    is_internal BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE knowledge_base (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100),
    is_published BOOLEAN DEFAULT TRUE,
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO agents (name, email, role) VALUES
('Support Admin', 'admin@support.com', 'admin'),
('Agent 1', 'agent1@support.com', 'agent'),
('Agent 2', 'agent2@support.com', 'agent');

INSERT INTO tickets (ticket_number, subject, description, priority, customer_email, customer_name) VALUES
('TKT-001', 'Cannot login', 'Getting error when trying to login', 'high', 'user1@test.com', 'John User'),
('TKT-002', 'Feature request', 'Would like dark mode', 'low', 'user2@test.com', 'Jane User');

CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_assigned ON tickets(assigned_to);
