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

// Upload video (metadata)
app.post('/api/videos', async (req, res) => {
    try {
        const { title, description, user_id, file_key } = req.body;
        const result = await pool.query(
            `INSERT INTO videos (title, description, user_id, file_key, status)
             VALUES ($1, $2, $3, $4, 'processing') RETURNING *`,
            [title, description, user_id, file_key]
        );

        // Queue transcoding job
        await redisClient.lPush('transcode_queue', JSON.stringify(result.rows[0]));

        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Get videos
app.get('/api/videos', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT v.*, u.name as uploader_name,
                   COUNT(vv.id) as view_count
            FROM videos v
            LEFT JOIN users u ON v.user_id = u.id
            LEFT JOIN video_views vv ON v.id = vv.video_id
            WHERE v.status = 'ready' AND v.is_public = true
            GROUP BY v.id, u.name
            ORDER BY v.created_at DESC
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get video with streaming URLs
app.get('/api/videos/:id', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM videos WHERE id = $1', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });

        const video = result.rows[0];
        // Return HLS manifest URL
        video.stream_url = `/stream/${video.file_key}/master.m3u8`;

        res.json(video);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Record view
app.post('/api/videos/:id/view', async (req, res) => {
    try {
        const { user_id, watch_duration } = req.body;
        await pool.query(
            `INSERT INTO video_views (video_id, user_id, watch_duration_seconds)
             VALUES ($1, $2, $3)`,
            [req.params.id, user_id, watch_duration || 0]
        );
        res.json({ status: 'recorded' });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Like video
app.post('/api/videos/:id/like', async (req, res) => {
    try {
        const { user_id } = req.body;
        await pool.query(
            `INSERT INTO video_likes (video_id, user_id) VALUES ($1, $2)
             ON CONFLICT (video_id, user_id) DO DELETE`,
            [req.params.id, user_id]
        );
        res.json({ status: 'toggled' });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Add comment
app.post('/api/videos/:id/comments', async (req, res) => {
    try {
        const { user_id, content } = req.body;
        const result = await pool.query(
            `INSERT INTO comments (video_id, user_id, content) VALUES ($1, $2, $3) RETURNING *`,
            [req.params.id, user_id, content]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Video API running on port ${PORT}`));
