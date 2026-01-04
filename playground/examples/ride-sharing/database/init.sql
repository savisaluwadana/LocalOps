-- Ride Sharing Schema (PostGIS enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE riders (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    rating DECIMAL(2, 1) DEFAULT 5.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    vehicle_type VARCHAR(50),
    vehicle_model VARCHAR(100),
    license_plate VARCHAR(20),
    rating DECIMAL(2, 1) DEFAULT 5.0,
    is_available BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    current_lat DECIMAL(10, 8),
    current_lng DECIMAL(11, 8),
    location_updated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rides (
    id SERIAL PRIMARY KEY,
    ride_number VARCHAR(30) UNIQUE NOT NULL,
    rider_id INTEGER REFERENCES riders(id),
    driver_id INTEGER REFERENCES drivers(id),
    pickup_lat DECIMAL(10, 8) NOT NULL,
    pickup_lng DECIMAL(11, 8) NOT NULL,
    dropoff_lat DECIMAL(10, 8) NOT NULL,
    dropoff_lng DECIMAL(11, 8) NOT NULL,
    pickup_address TEXT,
    dropoff_address TEXT,
    estimated_fare DECIMAL(10, 2),
    final_fare DECIMAL(10, 2),
    status VARCHAR(50) DEFAULT 'requested',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancel_reason TEXT
);

CREATE TABLE ride_ratings (
    id SERIAL PRIMARY KEY,
    ride_id INTEGER REFERENCES rides(id),
    from_rider BOOLEAN,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO riders (name, email, phone) VALUES
('John Rider', 'rider@example.com', '555-1001');

INSERT INTO drivers (name, email, phone, vehicle_type, vehicle_model, is_available, is_verified) VALUES
('Mike Driver', 'driver@example.com', '555-2001', 'sedan', 'Toyota Camry', true, true);

CREATE INDEX idx_rides_status ON rides(status);
CREATE INDEX idx_rides_driver ON rides(driver_id);
CREATE INDEX idx_drivers_available ON drivers(is_available);
