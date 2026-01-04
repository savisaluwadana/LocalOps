CREATE TABLE urls (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE clicks (
    id SERIAL PRIMARY KEY,
    url_code VARCHAR(20) REFERENCES urls(code),
    ip_address VARCHAR(45),
    user_agent TEXT,
    referrer TEXT,
    clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_urls_code ON urls(code);
CREATE INDEX idx_clicks_url ON clicks(url_code);
CREATE INDEX idx_clicks_date ON clicks(clicked_at);
