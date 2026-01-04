-- Food Delivery Schema (PostGIS enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE restaurants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    cuisine_type VARCHAR(50),
    address TEXT,
    location GEOGRAPHY(POINT),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    opening_hours JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE menu_items (
    id SERIAL PRIMARY KEY,
    restaurant_id INTEGER REFERENCES restaurants(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100),
    image_url VARCHAR(500),
    is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    default_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    vehicle_type VARCHAR(50),
    is_available BOOLEAN DEFAULT TRUE,
    current_lat DECIMAL(10, 8),
    current_lng DECIMAL(11, 8)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES customers(id),
    restaurant_id INTEGER REFERENCES restaurants(id),
    driver_id INTEGER REFERENCES drivers(id),
    total_amount DECIMAL(10, 2),
    delivery_address TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    menu_item_id INTEGER REFERENCES menu_items(id),
    quantity INTEGER DEFAULT 1,
    price DECIMAL(10, 2)
);

CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    restaurant_id INTEGER REFERENCES restaurants(id),
    customer_id INTEGER REFERENCES customers(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO restaurants (name, cuisine_type, address, location) VALUES
('Pizza Palace', 'Italian', '123 Main St', ST_MakePoint(-73.9857, 40.7484)::geography),
('Sushi World', 'Japanese', '456 Oak Ave', ST_MakePoint(-73.9800, 40.7500)::geography),
('Burger Barn', 'American', '789 Elm St', ST_MakePoint(-73.9900, 40.7450)::geography);

INSERT INTO menu_items (restaurant_id, name, price, category) VALUES
(1, 'Margherita Pizza', 14.99, 'Pizza'),
(1, 'Pepperoni Pizza', 16.99, 'Pizza'),
(2, 'California Roll', 12.99, 'Sushi'),
(2, 'Salmon Sashimi', 18.99, 'Sashimi'),
(3, 'Classic Burger', 11.99, 'Burgers');

INSERT INTO customers (name, email) VALUES ('Test User', 'test@example.com');
INSERT INTO drivers (name, phone, vehicle_type) VALUES ('Driver 1', '555-0001', 'car');

CREATE INDEX idx_restaurants_location ON restaurants USING GIST(location);
CREATE INDEX idx_orders_status ON orders(status);
