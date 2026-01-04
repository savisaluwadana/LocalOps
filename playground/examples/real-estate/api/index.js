const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Health
app.get('/health', (req, res) => res.json({ status: 'healthy' }));

// Search properties
app.get('/api/properties', async (req, res) => {
    try {
        const { type, min_price, max_price, bedrooms, city } = req.query;
        let query = 'SELECT * FROM properties WHERE is_active = true';
        const params = [];

        if (type) { params.push(type); query += ` AND property_type = $${params.length}`; }
        if (min_price) { params.push(min_price); query += ` AND price >= $${params.length}`; }
        if (max_price) { params.push(max_price); query += ` AND price <= $${params.length}`; }
        if (bedrooms) { params.push(bedrooms); query += ` AND bedrooms >= $${params.length}`; }
        if (city) { params.push(city); query += ` AND city = $${params.length}`; }

        query += ' ORDER BY created_at DESC';
        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get property detail
app.get('/api/properties/:id', async (req, res) => {
    try {
        const property = await pool.query('SELECT * FROM properties WHERE id = $1', [req.params.id]);
        if (property.rows.length === 0) return res.status(404).json({ error: 'Not found' });

        const images = await pool.query(
            'SELECT * FROM property_images WHERE property_id = $1',
            [req.params.id]
        );

        const agent = await pool.query(
            'SELECT * FROM agents WHERE id = $1',
            [property.rows[0].agent_id]
        );

        res.json({
            ...property.rows[0],
            images: images.rows,
            agent: agent.rows[0]
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create inquiry
app.post('/api/properties/:id/inquire', async (req, res) => {
    try {
        const { name, email, phone, message } = req.body;
        const result = await pool.query(
            `INSERT INTO inquiries (property_id, name, email, phone, message)
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [req.params.id, name, email, phone, message]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Create property (agents)
app.post('/api/properties', async (req, res) => {
    try {
        const { title, description, property_type, listing_type, price, bedrooms, bathrooms, area_sqft, address, city, agent_id } = req.body;
        const result = await pool.query(
            `INSERT INTO properties (title, description, property_type, listing_type, price, bedrooms, bathrooms, area_sqft, address, city, agent_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
            [title, description, property_type, listing_type, price, bedrooms, bathrooms, area_sqft, address, city, agent_id]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Mortgage calculator
app.post('/api/mortgage/calculate', (req, res) => {
    const { principal, rate, years } = req.body;
    const monthlyRate = rate / 100 / 12;
    const payments = years * 12;
    const x = Math.pow(1 + monthlyRate, payments);
    const monthly = (principal * x * monthlyRate) / (x - 1);

    res.json({
        monthly_payment: monthly.toFixed(2),
        total_payment: (monthly * payments).toFixed(2),
        total_interest: (monthly * payments - principal).toFixed(2)
    });
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Real Estate API running on port ${PORT}`));
