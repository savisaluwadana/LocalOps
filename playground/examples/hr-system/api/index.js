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

// Get all employees
app.get('/api/employees', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT e.*, d.name as department_name 
            FROM employees e 
            LEFT JOIN departments d ON e.department_id = d.id
            WHERE e.is_active = true
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get employee by ID
app.get('/api/employees/:id', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM employees WHERE id = $1', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create employee
app.post('/api/employees', async (req, res) => {
    try {
        const { name, email, department_id, position, salary, hire_date } = req.body;
        const result = await pool.query(
            `INSERT INTO employees (name, email, department_id, position, salary, hire_date)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [name, email, department_id, position, salary, hire_date || new Date()]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Attendance check-in
app.post('/api/attendance/checkin', async (req, res) => {
    try {
        const { employee_id } = req.body;
        const result = await pool.query(
            `INSERT INTO attendance (employee_id, check_in) VALUES ($1, NOW()) RETURNING *`,
            [employee_id]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Attendance check-out
app.post('/api/attendance/checkout', async (req, res) => {
    try {
        const { employee_id } = req.body;
        const result = await pool.query(
            `UPDATE attendance SET check_out = NOW() 
             WHERE employee_id = $1 AND check_out IS NULL 
             ORDER BY check_in DESC LIMIT 1 RETURNING *`,
            [employee_id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Leave request
app.post('/api/leave/request', async (req, res) => {
    try {
        const { employee_id, leave_type, start_date, end_date, reason } = req.body;
        const result = await pool.query(
            `INSERT INTO leave_requests (employee_id, leave_type, start_date, end_date, reason)
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [employee_id, leave_type, start_date, end_date, reason]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Get payroll
app.get('/api/payroll/:month', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT p.*, e.name as employee_name 
             FROM payroll p 
             JOIN employees e ON p.employee_id = e.id
             WHERE p.month = $1`,
            [req.params.month]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`HR API running on port ${PORT}`));
