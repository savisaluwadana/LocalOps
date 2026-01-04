-- IoT Platform Schema

CREATE TABLE devices (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50),
    location VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alert_rules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    device_id VARCHAR(50) REFERENCES devices(device_id),
    metric VARCHAR(100),
    condition VARCHAR(20),
    threshold DECIMAL,
    action JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    rule_id INTEGER REFERENCES alert_rules(id),
    device_id VARCHAR(50),
    value DECIMAL,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP
);

-- Sample devices
INSERT INTO devices (device_id, name, type, location) VALUES
('sensor-001', 'Temperature Sensor 1', 'temperature', 'Building A'),
('sensor-002', 'Humidity Sensor 1', 'humidity', 'Building A'),
('sensor-003', 'Motion Detector', 'motion', 'Entrance');

CREATE INDEX idx_devices_type ON devices(type);
CREATE INDEX idx_alerts_device ON alerts(device_id);
