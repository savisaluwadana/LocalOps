CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER DEFAULT 0,
    category VARCHAR(100),
    sku VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_sku ON products(sku);

INSERT INTO products (name, description, price, stock, category, sku) VALUES
('Laptop Pro', 'High-performance laptop', 1299.99, 50, 'Electronics', 'LAPTOP-001'),
('Wireless Mouse', 'Ergonomic wireless mouse', 49.99, 200, 'Electronics', 'MOUSE-001'),
('USB-C Cable', 'Fast charging cable', 19.99, 500, 'Accessories', 'CABLE-001'),
('Mechanical Keyboard', 'RGB mechanical keyboard', 129.99, 75, 'Electronics', 'KB-001'),
('Monitor 27"', '4K IPS monitor', 399.99, 30, 'Electronics', 'MON-001');
