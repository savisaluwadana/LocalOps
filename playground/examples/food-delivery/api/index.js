const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const redisClient = redis.createClient({ url: process.env.REDIS_URL });
redisClient.connect().catch(console.error);

// Health
app.get('/health', (req, res) => res.json({ status: 'healthy' }));

// Get restaurants
app.get('/api/restaurants', async (req, res) => {
    try {
        const { lat, lng, radius } = req.query;
        let query = `SELECT r.*, 
            COALESCE(AVG(rv.rating), 0) as avg_rating,
            COUNT(rv.id) as review_count
            FROM restaurants r
            LEFT JOIN reviews rv ON r.id = rv.restaurant_id
            WHERE r.is_active = true`;

        if (lat && lng) {
            query += ` AND ST_DWithin(r.location, ST_MakePoint(${lng}, ${lat})::geography, ${radius || 5000})`;
        }
        query += ' GROUP BY r.id ORDER BY avg_rating DESC';

        const result = await pool.query(query);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get menu
app.get('/api/restaurants/:id/menu', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT * FROM menu_items WHERE restaurant_id = $1 AND is_available = true',
            [req.params.id]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create order
app.post('/api/orders', async (req, res) => {
    try {
        const { customer_id, restaurant_id, items, delivery_address } = req.body;
        const orderNumber = `ORD${Date.now()}`;

        // Calculate total
        let total = 0;
        for (const item of items) {
            const menuItem = await pool.query('SELECT price FROM menu_items WHERE id = $1', [item.menu_item_id]);
            total += menuItem.rows[0].price * item.quantity;
        }

        const result = await pool.query(
            `INSERT INTO orders (order_number, customer_id, restaurant_id, total_amount, delivery_address, status)
             VALUES ($1, $2, $3, $4, $5, 'pending') RETURNING *`,
            [orderNumber, customer_id, restaurant_id, total, delivery_address]
        );

        // Add order items
        for (const item of items) {
            await pool.query(
                'INSERT INTO order_items (order_id, menu_item_id, quantity, price) VALUES ($1, $2, $3, (SELECT price FROM menu_items WHERE id = $2))',
                [result.rows[0].id, item.menu_item_id, item.quantity]
            );
        }

        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Track order
app.get('/api/orders/:id/track', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT o.*, d.name as driver_name, d.phone as driver_phone,
                   d.current_lat, d.current_lng
            FROM orders o
            LEFT JOIN drivers d ON o.driver_id = d.id
            WHERE o.id = $1
        `, [req.params.id]);
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Update order status
app.put('/api/orders/:id/status', async (req, res) => {
    try {
        const { status, driver_id } = req.body;
        const result = await pool.query(
            `UPDATE orders SET status = $1, driver_id = COALESCE($2, driver_id), updated_at = NOW()
             WHERE id = $3 RETURNING *`,
            [status, driver_id, req.params.id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Food Delivery API running on port ${PORT}`));
