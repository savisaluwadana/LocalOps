-- CRM Schema

CREATE TABLE contacts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    company VARCHAR(100),
    notes TEXT,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE deals (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    contact_id INTEGER REFERENCES contacts(id),
    value DECIMAL(12, 2),
    stage VARCHAR(50) DEFAULT 'lead',
    expected_close DATE,
    is_active BOOLEAN DEFAULT TRUE,
    won_at TIMESTAMP,
    lost_at TIMESTAMP,
    lost_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE activities (
    id SERIAL PRIMARY KEY,
    contact_id INTEGER REFERENCES contacts(id),
    deal_id INTEGER REFERENCES deals(id),
    type VARCHAR(50) NOT NULL,
    notes TEXT,
    scheduled_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO contacts (name, email, phone, company) VALUES
('Alice Johnson', 'alice@techcorp.com', '555-0101', 'TechCorp'),
('Bob Smith', 'bob@startup.io', '555-0102', 'Startup.io'),
('Carol White', 'carol@enterprise.com', '555-0103', 'Enterprise Inc');

INSERT INTO deals (title, contact_id, value, stage, expected_close) VALUES
('TechCorp Enterprise License', 1, 50000, 'proposal', '2024-03-15'),
('Startup.io Pilot', 2, 15000, 'negotiation', '2024-02-28'),
('Enterprise Annual Contract', 3, 120000, 'lead', '2024-06-01');

CREATE INDEX idx_deals_stage ON deals(stage);
CREATE INDEX idx_deals_contact ON deals(contact_id);
CREATE INDEX idx_activities_contact ON activities(contact_id);
