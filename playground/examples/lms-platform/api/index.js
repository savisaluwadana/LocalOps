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

// Get courses
app.get('/api/courses', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT c.*, u.name as instructor_name,
                   COUNT(DISTINCT e.id) as enrolled_count
            FROM courses c
            LEFT JOIN users u ON c.instructor_id = u.id
            LEFT JOIN enrollments e ON c.id = e.course_id
            WHERE c.is_published = true
            GROUP BY c.id, u.name
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get course with lessons
app.get('/api/courses/:id', async (req, res) => {
    try {
        const course = await pool.query('SELECT * FROM courses WHERE id = $1', [req.params.id]);
        const lessons = await pool.query(
            'SELECT * FROM lessons WHERE course_id = $1 ORDER BY order_index',
            [req.params.id]
        );
        res.json({ ...course.rows[0], lessons: lessons.rows });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Enroll in course
app.post('/api/courses/:id/enroll', async (req, res) => {
    try {
        const { user_id } = req.body;
        const result = await pool.query(
            `INSERT INTO enrollments (user_id, course_id) VALUES ($1, $2) 
             ON CONFLICT (user_id, course_id) DO NOTHING RETURNING *`,
            [user_id, req.params.id]
        );
        res.status(201).json(result.rows[0] || { message: 'Already enrolled' });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Get user progress
app.get('/api/progress/:courseId', async (req, res) => {
    try {
        const { user_id } = req.query;
        const result = await pool.query(`
            SELECT l.id, l.title, lp.completed_at IS NOT NULL as completed
            FROM lessons l
            LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = $1
            WHERE l.course_id = $2
            ORDER BY l.order_index
        `, [user_id, req.params.courseId]);

        const completed = result.rows.filter(r => r.completed).length;
        const total = result.rows.length;

        res.json({
            lessons: result.rows,
            progress: total > 0 ? Math.round((completed / total) * 100) : 0
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Mark lesson complete
app.post('/api/lessons/:id/complete', async (req, res) => {
    try {
        const { user_id } = req.body;
        const result = await pool.query(
            `INSERT INTO lesson_progress (user_id, lesson_id, completed_at)
             VALUES ($1, $2, NOW())
             ON CONFLICT (user_id, lesson_id) DO UPDATE SET completed_at = NOW()
             RETURNING *`,
            [user_id, req.params.id]
        );

        // Check if course completed
        const lesson = await pool.query('SELECT course_id FROM lessons WHERE id = $1', [req.params.id]);
        const progress = await pool.query(`
            SELECT COUNT(*) as total, 
                   COUNT(lp.id) as completed
            FROM lessons l
            LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = $1
            WHERE l.course_id = $2
        `, [user_id, lesson.rows[0].course_id]);

        if (progress.rows[0].total === progress.rows[0].completed) {
            // Issue certificate
            await pool.query(
                `INSERT INTO certificates (user_id, course_id, issued_at)
                 VALUES ($1, $2, NOW()) ON CONFLICT DO NOTHING`,
                [user_id, lesson.rows[0].course_id]
            );
        }

        res.json(result.rows[0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`LMS API running on port ${PORT}`));
