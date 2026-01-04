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

// Contacts
app.get('/api/contacts', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM contacts ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/contacts', async (req, res) => {
    try {
        const { name, email, phone, company, notes } = req.body;
        const result = await pool.query(
            `INSERT INTO contacts (name, email, phone, company, notes) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [name, email, phone, company, notes]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Deals
app.get('/api/deals', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT d.*, c.name as contact_name 
            FROM deals d 
            LEFT JOIN contacts c ON d.contact_id = c.id
            ORDER BY d.created_at DESC
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/deals', async (req, res) => {
    try {
        const { title, contact_id, value, stage, expected_close } = req.body;
        const result = await pool.query(
            `INSERT INTO deals (title, contact_id, value, stage, expected_close) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [title, contact_id, value, stage || 'lead', expected_close]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

app.put('/api/deals/:id/stage', async (req, res) => {
    try {
        const { stage } = req.body;
        const result = await pool.query(
            'UPDATE deals SET stage = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
            [stage, req.params.id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Activities
app.post('/api/activities', async (req, res) => {
    try {
        const { contact_id, deal_id, type, notes, scheduled_at } = req.body;
        const result = await pool.query(
            `INSERT INTO activities (contact_id, deal_id, type, notes, scheduled_at) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [contact_id, deal_id, type, notes, scheduled_at]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Pipeline report
app.get('/api/reports/pipeline', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT stage, COUNT(*) as count, SUM(value) as total_value
            FROM deals WHERE is_active = true
            GROUP BY stage
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`CRM API running on port ${PORT}`));
