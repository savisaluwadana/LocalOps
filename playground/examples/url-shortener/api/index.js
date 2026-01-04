const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');
const crypto = require('crypto');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const redisClient = redis.createClient({ url: process.env.REDIS_URL });
redisClient.connect().catch(console.error);

const BASE_URL = process.env.BASE_URL || 'http://localhost:8000';
const CHARS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

// Generate short code
function generateCode(length = 7) {
    let code = '';
    const bytes = crypto.randomBytes(length);
    for (let i = 0; i < length; i++) {
        code += CHARS[bytes[i] % CHARS.length];
    }
    return code;
}

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

// Create short URL
app.post('/api/shorten', async (req, res) => {
    try {
        const { url, custom_code, expires_at } = req.body;

        if (!url) {
            return res.status(400).json({ error: 'URL is required' });
        }

        const code = custom_code || generateCode();

        // Check if custom code exists
        if (custom_code) {
            const existing = await pool.query('SELECT id FROM urls WHERE code = $1', [code]);
            if (existing.rows.length > 0) {
                return res.status(409).json({ error: 'Code already exists' });
            }
        }

        const result = await pool.query(
            `INSERT INTO urls (code, original_url, expires_at)
             VALUES ($1, $2, $3) RETURNING *`,
            [code, url, expires_at || null]
        );

        // Cache the URL
        await redisClient.set(`url:${code}`, url, { EX: 3600 });

        res.status(201).json({
            code,
            short_url: `${BASE_URL}/${code}`,
            original_url: url
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Redirect to original URL
app.get('/:code', async (req, res) => {
    try {
        const { code } = req.params;

        // Check cache first
        let url = await redisClient.get(`url:${code}`);

        if (!url) {
            const result = await pool.query(
                `SELECT original_url, expires_at FROM urls 
                 WHERE code = $1 AND (expires_at IS NULL OR expires_at > NOW())`,
                [code]
            );

            if (result.rows.length === 0) {
                return res.status(404).json({ error: 'URL not found' });
            }

            url = result.rows[0].original_url;
            await redisClient.set(`url:${code}`, url, { EX: 3600 });
        }

        // Track click (async)
        pool.query(
            'INSERT INTO clicks (url_code, ip_address, user_agent, referrer) VALUES ($1, $2, $3, $4)',
            [code, req.ip, req.headers['user-agent'], req.headers['referer'] || null]
        ).catch(console.error);

        res.redirect(301, url);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get URL stats
app.get('/api/stats/:code', async (req, res) => {
    try {
        const { code } = req.params;

        const urlResult = await pool.query('SELECT * FROM urls WHERE code = $1', [code]);
        if (urlResult.rows.length === 0) {
            return res.status(404).json({ error: 'URL not found' });
        }

        const statsResult = await pool.query(`
            SELECT 
                COUNT(*) as total_clicks,
                COUNT(DISTINCT ip_address) as unique_visitors,
                MAX(clicked_at) as last_click
            FROM clicks WHERE url_code = $1
        `, [code]);

        res.json({
            url: urlResult.rows[0],
            stats: statsResult.rows[0]
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`URL Shortener running on port ${PORT}`));
