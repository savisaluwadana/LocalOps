const express = require('express');
const { Pool } = require('pg');
const axios = require('axios');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const PRODUCT_SERVICE = process.env.PRODUCT_SERVICE_URL;
const USER_SERVICE = process.env.USER_SERVICE_URL;

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'order-service' });
});

// Get orders for user
app.get('/orders', async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        const result = await pool.query(
            'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC',
            [userId]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get order by ID
app.get('/orders/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const orderResult = await pool.query('SELECT * FROM orders WHERE id = $1', [id]);
        if (orderResult.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const itemsResult = await pool.query(
            'SELECT * FROM order_items WHERE order_id = $1',
            [id]
        );

        res.json({
            ...orderResult.rows[0],
            items: itemsResult.rows
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create order
app.post('/orders', async (req, res) => {
    const client = await pool.connect();

    try {
        const { user_id, items, shipping_address } = req.body;

        await client.query('BEGIN');

        // Calculate total and verify stock
        let total = 0;
        for (const item of items) {
            const productRes = await axios.get(`${PRODUCT_SERVICE}/products/${item.product_id}`);
            const product = productRes.data;

            if (product.stock < item.quantity) {
                throw new Error(`Insufficient stock for ${product.name}`);
            }

            total += product.price * item.quantity;
            item.unit_price = product.price;
        }

        // Create order
        const orderResult = await client.query(
            `INSERT INTO orders (user_id, total_amount, shipping_address, status)
             VALUES ($1, $2, $3, 'pending') RETURNING *`,
            [user_id, total, shipping_address]
        );
        const order = orderResult.rows[0];

        // Create order items and update stock
        for (const item of items) {
            await client.query(
                `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
                 VALUES ($1, $2, $3, $4)`,
                [order.id, item.product_id, item.quantity, item.unit_price]
            );

            await axios.patch(`${PRODUCT_SERVICE}/products/${item.product_id}/stock`, {
                quantity: -item.quantity
            });
        }

        await client.query('COMMIT');
        res.status(201).json(order);
    } catch (err) {
        await client.query('ROLLBACK');
        res.status(400).json({ error: err.message });
    } finally {
        client.release();
    }
});

// Update order status
app.patch('/orders/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const result = await pool.query(
            'UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
            [status, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 3002;
app.listen(PORT, () => console.log(`Order Service running on port ${PORT}`));
