const express = require('express');
const { Pool } = require('pg');
const mqtt = require('mqtt');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const mqttClient = mqtt.connect(process.env.MQTT_URL || 'mqtt://mqtt-broker:1883');

mqttClient.on('connect', () => {
    console.log('Connected to MQTT broker');
    mqttClient.subscribe('devices/+/telemetry');
});

// Health
app.get('/health', (req, res) => res.json({ status: 'healthy' }));

// Register device
app.post('/api/devices', async (req, res) => {
    try {
        const { device_id, name, type, location, metadata } = req.body;
        const result = await pool.query(
            `INSERT INTO devices (device_id, name, type, location, metadata)
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [device_id, name, type, location, metadata || {}]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Get all devices
app.get('/api/devices', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM devices ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get device telemetry
app.get('/api/devices/:id/telemetry', async (req, res) => {
    try {
        const timescale = new Pool({ connectionString: process.env.TIMESCALE_URL });
        const result = await timescale.query(`
            SELECT * FROM telemetry 
            WHERE device_id = $1 
            ORDER BY time DESC 
            LIMIT 100
        `, [req.params.id]);
        await timescale.end();
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Send command to device
app.post('/api/devices/:id/command', async (req, res) => {
    try {
        const { command, payload } = req.body;
        const topic = `devices/${req.params.id}/commands`;
        mqttClient.publish(topic, JSON.stringify({ command, payload }));
        res.json({ status: 'sent', topic });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create alert rule
app.post('/api/rules', async (req, res) => {
    try {
        const { name, device_id, metric, condition, threshold, action } = req.body;
        const result = await pool.query(
            `INSERT INTO alert_rules (name, device_id, metric, condition, threshold, action)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [name, device_id, metric, condition, threshold, action]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`IoT API running on port ${PORT}`));
