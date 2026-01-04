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

// Create account
app.post('/api/accounts', async (req, res) => {
    try {
        const { customer_id, type, currency } = req.body;
        const accountNumber = `ACC${Date.now()}`;
        const result = await pool.query(
            `INSERT INTO accounts (account_number, customer_id, type, currency, balance)
             VALUES ($1, $2, $3, $4, 0) RETURNING *`,
            [accountNumber, customer_id, type || 'checking', currency || 'USD']
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Get account
app.get('/api/accounts/:id', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM accounts WHERE id = $1', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Transfer funds
app.post('/api/transfers', async (req, res) => {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const { from_account, to_account, amount, description } = req.body;

        // Debit source
        const debit = await client.query(
            `UPDATE accounts SET balance = balance - $1 WHERE account_number = $2 AND balance >= $1 RETURNING *`,
            [amount, from_account]
        );
        if (debit.rows.length === 0) throw new Error('Insufficient funds');

        // Credit destination
        await client.query(
            `UPDATE accounts SET balance = balance + $1 WHERE account_number = $2`,
            [amount, to_account]
        );

        // Record transaction
        const txn = await client.query(
            `INSERT INTO transactions (from_account, to_account, amount, type, description, status)
             VALUES ($1, $2, $3, 'transfer', $4, 'completed') RETURNING *`,
            [from_account, to_account, amount, description]
        );

        await client.query('COMMIT');
        res.status(201).json(txn.rows[0]);
    } catch (err) {
        await client.query('ROLLBACK');
        res.status(400).json({ error: err.message });
    } finally {
        client.release();
    }
});

// Get transactions
app.get('/api/accounts/:number/transactions', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM transactions 
            WHERE from_account = $1 OR to_account = $1
            ORDER BY created_at DESC LIMIT 50
        `, [req.params.number]);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get balance
app.get('/api/accounts/:number/balance', async (req, res) => {
    try {
        const result = await pool.query('SELECT balance FROM accounts WHERE account_number = $1', [req.params.number]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
        res.json({ balance: result.rows[0].balance });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Banking API running on port ${PORT}`));
