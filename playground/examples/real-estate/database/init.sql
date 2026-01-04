-- Real Estate Schema

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE agents (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    photo_url VARCHAR(500),
    bio TEXT,
    license_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE properties (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    property_type VARCHAR(50),
    listing_type VARCHAR(20),
    price DECIMAL(15, 2),
    bedrooms INTEGER,
    bathrooms INTEGER,
    area_sqft INTEGER,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    location GEOGRAPHY(POINT),
    agent_id INTEGER REFERENCES agents(id),
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE property_images (
    id SERIAL PRIMARY KEY,
    property_id INTEGER REFERENCES properties(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    order_index INTEGER
);

CREATE TABLE inquiries (
    id SERIAL PRIMARY KEY,
    property_id INTEGER REFERENCES properties(id),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    message TEXT,
    status VARCHAR(50) DEFAULT 'new',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    property_id INTEGER REFERENCES properties(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, property_id)
);

-- Sample data
INSERT INTO agents (name, email, phone, license_number) VALUES
('Sarah Agent', 'sarah@realty.com', '555-0001', 'LIC123456');

INSERT INTO properties (title, property_type, listing_type, price, bedrooms, bathrooms, area_sqft, address, city, state, agent_id) VALUES
('Modern Downtown Condo', 'condo', 'sale', 450000, 2, 2, 1200, '123 Main St', 'New York', 'NY', 1),
('Family Home with Garden', 'house', 'sale', 750000, 4, 3, 2500, '456 Oak Ave', 'Brooklyn', 'NY', 1),
('Cozy Studio Apartment', 'apartment', 'rent', 2500, 0, 1, 500, '789 Park Blvd', 'Manhattan', 'NY', 1);

CREATE INDEX idx_properties_type ON properties(property_type);
CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_price ON properties(price);
