const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
app.use(express.json());

// Database connection
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Redis connection
const redisClient = redis.createClient({ url: process.env.REDIS_URL });
redisClient.connect().catch(console.error);

// ============================================
// Routes
// ============================================

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'product-service' });
});

// Get all products (with caching)
app.get('/products', async (req, res) => {
    try {
        const cacheKey = 'products:all';
        const cached = await redisClient.get(cacheKey);

        if (cached) {
            return res.json(JSON.parse(cached));
        }

        const result = await pool.query(
            'SELECT * FROM products WHERE is_active = true ORDER BY created_at DESC LIMIT 100'
        );

        await redisClient.setEx(cacheKey, 300, JSON.stringify(result.rows));
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get product by ID
app.get('/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query('SELECT * FROM products WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create product
app.post('/products', async (req, res) => {
    try {
        const { name, description, price, stock, category, sku } = req.body;

        const result = await pool.query(
            `INSERT INTO products (name, description, price, stock, category, sku)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [name, description, price, stock, category, sku]
        );

        // Invalidate cache
        await redisClient.del('products:all');

        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Update stock
app.patch('/products/:id/stock', async (req, res) => {
    try {
        const { id } = req.params;
        const { quantity } = req.body;

        const result = await pool.query(
            'UPDATE products SET stock = stock + $1, updated_at = NOW() WHERE id = $2 RETURNING *',
            [quantity, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        await redisClient.del('products:all');
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Search products
app.get('/products/search/:query', async (req, res) => {
    try {
        const { query } = req.params;
        const result = await pool.query(
            `SELECT * FROM products 
             WHERE is_active = true 
             AND (name ILIKE $1 OR description ILIKE $1 OR category ILIKE $1)`,
            [`%${query}%`]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`Product Service running on port ${PORT}`));
