-- POS System Database Schema

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('cashier', 'manager', 'admin')),
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INTEGER REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    barcode VARCHAR(50) UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INTEGER REFERENCES categories(id),
    price DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2) DEFAULT 0,
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inventory table
CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id) UNIQUE,
    quantity INTEGER DEFAULT 0,
    min_quantity INTEGER DEFAULT 10,
    max_quantity INTEGER DEFAULT 100,
    last_restock TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sales table
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    sale_number VARCHAR(20) UNIQUE NOT NULL,
    cashier_id INTEGER REFERENCES users(id),
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_total DECIMAL(10, 2) DEFAULT 0,
    discount_total DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sale items table
CREATE TABLE sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER REFERENCES sales(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    tax DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL
);

-- Refunds table
CREATE TABLE refunds (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER REFERENCES sales(id),
    amount DECIMAL(10, 2) NOT NULL,
    reason TEXT,
    processed_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default data
INSERT INTO users (username, password_hash, role, name) VALUES
('admin', '$2b$10$hash', 'admin', 'System Admin'),
('cashier1', '$2b$10$hash', 'cashier', 'John Cashier');

INSERT INTO categories (name) VALUES
('Electronics'),
('Food & Beverages'),
('Clothing'),
('Home & Kitchen');

INSERT INTO products (sku, barcode, name, category_id, price, cost, tax_rate) VALUES
('ELEC-001', '1234567890123', 'Wireless Earbuds', 1, 49.99, 25.00, 8.5),
('ELEC-002', '1234567890124', 'Phone Charger', 1, 19.99, 8.00, 8.5),
('FOOD-001', '2234567890123', 'Organic Coffee', 2, 14.99, 7.00, 0),
('FOOD-002', '2234567890124', 'Snack Bar', 2, 2.99, 1.20, 0),
('CLTH-001', '3234567890123', 'T-Shirt', 3, 24.99, 10.00, 8.5);

INSERT INTO inventory (product_id, quantity, min_quantity) VALUES
(1, 50, 10),
(2, 100, 20),
(3, 30, 5),
(4, 200, 50),
(5, 75, 15);

CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_sales_date ON sales(created_at);
CREATE INDEX idx_inventory_product ON inventory(product_id);
