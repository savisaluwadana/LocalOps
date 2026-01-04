-- Banking Schema

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    kyc_status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES customers(id),
    type VARCHAR(50) DEFAULT 'checking',
    currency VARCHAR(3) DEFAULT 'USD',
    balance DECIMAL(15, 2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(30) UNIQUE DEFAULT gen_random_uuid()::TEXT,
    from_account VARCHAR(20),
    to_account VARCHAR(20),
    amount DECIMAL(15, 2) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50),
    entity_id VARCHAR(50),
    action VARCHAR(50),
    actor_id INTEGER,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO customers (customer_id, name, email, kyc_status) VALUES
('CUST001', 'John Doe', 'john@example.com', 'verified'),
('CUST002', 'Jane Smith', 'jane@example.com', 'verified');

INSERT INTO accounts (account_number, customer_id, type, balance) VALUES
('ACC1001', 1, 'checking', 5000.00),
('ACC1002', 1, 'savings', 10000.00),
('ACC2001', 2, 'checking', 3000.00);

CREATE INDEX idx_txn_from ON transactions(from_account);
CREATE INDEX idx_txn_to ON transactions(to_account);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);
