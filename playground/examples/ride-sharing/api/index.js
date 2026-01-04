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

// Request ride
app.post('/api/rides/request', async (req, res) => {
    try {
        const { rider_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng } = req.body;
        const rideNumber = `RIDE${Date.now()}`;

        // Calculate estimated fare (simplified)
        const distance = Math.sqrt(
            Math.pow(dropoff_lat - pickup_lat, 2) + Math.pow(dropoff_lng - pickup_lng, 2)
        ) * 111; // rough km conversion
        const fare = Math.max(5, distance * 2.5);

        const result = await pool.query(
            `INSERT INTO rides (ride_number, rider_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, estimated_fare, status)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 'requested') RETURNING *`,
            [rideNumber, rider_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, fare.toFixed(2)]
        );

        // Notify nearby drivers (via Redis pub/sub)
        await redisClient.publish('ride_requests', JSON.stringify(result.rows[0]));

        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Accept ride (driver)
app.post('/api/rides/:id/accept', async (req, res) => {
    try {
        const { driver_id } = req.body;
        const result = await pool.query(
            `UPDATE rides SET driver_id = $1, status = 'accepted', accepted_at = NOW()
             WHERE id = $2 AND status = 'requested' RETURNING *`,
            [driver_id, req.params.id]
        );
        if (result.rows.length === 0) return res.status(400).json({ error: 'Ride not available' });
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Start ride
app.post('/api/rides/:id/start', async (req, res) => {
    try {
        const result = await pool.query(
            `UPDATE rides SET status = 'in_progress', started_at = NOW() WHERE id = $1 RETURNING *`,
            [req.params.id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Complete ride
app.post('/api/rides/:id/complete', async (req, res) => {
    try {
        const result = await pool.query(
            `UPDATE rides SET status = 'completed', completed_at = NOW(), final_fare = estimated_fare
             WHERE id = $1 RETURNING *`,
            [req.params.id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Update driver location
app.post('/api/drivers/:id/location', async (req, res) => {
    try {
        const { lat, lng } = req.body;
        await pool.query(
            'UPDATE drivers SET current_lat = $1, current_lng = $2, location_updated_at = NOW() WHERE id = $3',
            [lat, lng, req.params.id]
        );
        // Store in Redis for fast lookup
        await redisClient.geoAdd('driver_locations', { longitude: lng, latitude: lat, member: req.params.id });
        res.json({ status: 'updated' });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Get nearby drivers
app.get('/api/drivers/nearby', async (req, res) => {
    try {
        const { lat, lng, radius } = req.query;
        const drivers = await redisClient.geoSearch('driver_locations', {
            longitude: parseFloat(lng),
            latitude: parseFloat(lat)
        }, { radius: parseFloat(radius) || 5000, unit: 'm' });
        res.json(drivers);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Ride Sharing API running on port ${PORT}`));
