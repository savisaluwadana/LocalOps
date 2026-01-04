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

// Create ticket
app.post('/api/tickets', async (req, res) => {
    try {
        const { subject, description, priority, category, customer_email, customer_name } = req.body;
        const ticketNumber = `TKT-${Date.now()}`;
        const result = await pool.query(
            `INSERT INTO tickets (ticket_number, subject, description, priority, category, customer_email, customer_name)
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [ticketNumber, subject, description, priority || 'medium', category, customer_email, customer_name]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Get all tickets
app.get('/api/tickets', async (req, res) => {
    try {
        const { status, priority, assigned_to } = req.query;
        let query = 'SELECT * FROM tickets WHERE 1=1';
        const params = [];

        if (status) { params.push(status); query += ` AND status = $${params.length}`; }
        if (priority) { params.push(priority); query += ` AND priority = $${params.length}`; }
        if (assigned_to) { params.push(assigned_to); query += ` AND assigned_to = $${params.length}`; }

        query += ' ORDER BY created_at DESC';
        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Assign ticket
app.put('/api/tickets/:id/assign', async (req, res) => {
    try {
        const { agent_id } = req.body;
        const result = await pool.query(
            `UPDATE tickets SET assigned_to = $1, status = 'assigned', updated_at = NOW() 
             WHERE id = $2 RETURNING *`,
            [agent_id, req.params.id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Resolve ticket
app.put('/api/tickets/:id/resolve', async (req, res) => {
    try {
        const { resolution } = req.body;
        const result = await pool.query(
            `UPDATE tickets SET status = 'resolved', resolution = $1, resolved_at = NOW(), updated_at = NOW() 
             WHERE id = $2 RETURNING *`,
            [resolution, req.params.id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Add comment
app.post('/api/tickets/:id/comments', async (req, res) => {
    try {
        const { content, author_id, is_internal } = req.body;
        const result = await pool.query(
            `INSERT INTO ticket_comments (ticket_id, content, author_id, is_internal)
             VALUES ($1, $2, $3, $4) RETURNING *`,
            [req.params.id, content, author_id, is_internal || false]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// SLA Report
app.get('/api/reports/sla', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE status = 'resolved') as resolved,
                COUNT(*) FILTER (WHERE status = 'open') as open,
                AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_resolution_hours
            FROM tickets
            WHERE created_at > NOW() - INTERVAL '30 days'
        `);
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Helpdesk API running on port ${PORT}`));
