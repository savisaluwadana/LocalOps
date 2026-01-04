const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const redisClient = redis.createClient({ url: process.env.REDIS_URL });
redisClient.connect().catch(console.error);

const JWT_SECRET = process.env.JWT_SECRET || 'secret';

// ============================================
// Authentication Middleware
// ============================================
const authenticate = async (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorized' });

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
};

// ============================================
// Health Check
// ============================================
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'pos-api' });
});

// ============================================
// Products
// ============================================
app.get('/api/products', async (req, res) => {
    try {
        const cached = await redisClient.get('products:all');
        if (cached) return res.json(JSON.parse(cached));

        const result = await pool.query(`
            SELECT p.*, i.quantity as stock, c.name as category_name
            FROM products p
            LEFT JOIN inventory i ON p.id = i.product_id
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = true
        `);

        await redisClient.setEx('products:all', 300, JSON.stringify(result.rows));
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/products/barcode/:barcode', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT * FROM products WHERE barcode = $1 AND is_active = true',
            [req.params.barcode]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================
// Sales
// ============================================
app.post('/api/sales', authenticate, async (req, res) => {
    const client = await pool.connect();

    try {
        const { items, payment_method } = req.body;

        await client.query('BEGIN');

        // Generate sale number
        const saleNumber = `SALE-${Date.now()}`;

        // Calculate totals
        let subtotal = 0;
        let taxTotal = 0;

        for (const item of items) {
            const productRes = await client.query(
                'SELECT * FROM products WHERE id = $1',
                [item.product_id]
            );
            const product = productRes.data.rows[0];

            const itemTotal = product.price * item.quantity;
            const itemTax = itemTotal * (product.tax_rate / 100);

            subtotal += itemTotal;
            taxTotal += itemTax;

            item.unit_price = product.price;
            item.tax = itemTax;
            item.total = itemTotal + itemTax;
        }

        const total = subtotal + taxTotal;

        // Create sale
        const saleResult = await client.query(
            `INSERT INTO sales (sale_number, cashier_id, subtotal, tax_total, total, payment_method)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [saleNumber, req.user.id, subtotal, taxTotal, total, payment_method]
        );
        const sale = saleResult.rows[0];

        // Create sale items and update inventory
        for (const item of items) {
            await client.query(
                `INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, tax, total)
                 VALUES ($1, $2, $3, $4, $5, $6)`,
                [sale.id, item.product_id, item.quantity, item.unit_price, item.tax, item.total]
            );

            await client.query(
                'UPDATE inventory SET quantity = quantity - $1, updated_at = NOW() WHERE product_id = $2',
                [item.quantity, item.product_id]
            );
        }

        await client.query('COMMIT');

        // Invalidate cache
        await redisClient.del('products:all');

        res.status(201).json(sale);
    } catch (err) {
        await client.query('ROLLBACK');
        res.status(400).json({ error: err.message });
    } finally {
        client.release();
    }
});

app.get('/api/sales/:id', authenticate, async (req, res) => {
    try {
        const saleResult = await pool.query('SELECT * FROM sales WHERE id = $1', [req.params.id]);
        if (saleResult.rows.length === 0) {
            return res.status(404).json({ error: 'Sale not found' });
        }

        const itemsResult = await pool.query(`
            SELECT si.*, p.name as product_name, p.sku
            FROM sale_items si
            JOIN products p ON si.product_id = p.id
            WHERE si.sale_id = $1
        `, [req.params.id]);

        res.json({
            ...saleResult.rows[0],
            items: itemsResult.rows
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================
// Reports
// ============================================
app.get('/api/reports/daily', authenticate, async (req, res) => {
    try {
        const date = req.query.date || new Date().toISOString().split('T')[0];

        const result = await pool.query(`
            SELECT 
                COUNT(*) as total_sales,
                SUM(total) as total_revenue,
                SUM(tax_total) as total_tax,
                AVG(total) as average_sale
            FROM sales
            WHERE DATE(created_at) = $1
        `, [date]);

        const topProducts = await pool.query(`
            SELECT p.name, SUM(si.quantity) as units_sold, SUM(si.total) as revenue
            FROM sale_items si
            JOIN products p ON si.product_id = p.id
            JOIN sales s ON si.sale_id = s.id
            WHERE DATE(s.created_at) = $1
            GROUP BY p.id, p.name
            ORDER BY units_sold DESC
            LIMIT 10
        `, [date]);

        res.json({
            date,
            summary: result.rows[0],
            topProducts: topProducts.rows
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================
// Inventory
// ============================================
app.get('/api/inventory', authenticate, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT i.*, p.name, p.sku,
                   CASE WHEN i.quantity <= i.min_quantity THEN true ELSE false END as low_stock
            FROM inventory i
            JOIN products p ON i.product_id = p.id
            ORDER BY i.quantity ASC
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/inventory/low-stock', authenticate, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT i.*, p.name, p.sku
            FROM inventory i
            JOIN products p ON i.product_id = p.id
            WHERE i.quantity <= i.min_quantity
            ORDER BY i.quantity ASC
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`POS API running on port ${PORT}`));
