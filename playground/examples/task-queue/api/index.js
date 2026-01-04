const express = require('express');
const { Queue } = require('bullmq');
const Redis = require('ioredis');

const app = express();
app.use(express.json());

const connection = new Redis(process.env.REDIS_URL);

// Create queues
const queues = {
    email: new Queue('email', { connection }),
    'image-resize': new Queue('image-resize', { connection }),
    export: new Queue('export', { connection }),
};

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

// Add job to queue
app.post('/api/jobs', async (req, res) => {
    try {
        const { type, data, options = {} } = req.body;

        if (!queues[type]) {
            return res.status(400).json({ error: `Unknown job type: ${type}` });
        }

        const job = await queues[type].add(type, data, {
            attempts: options.attempts || 3,
            backoff: {
                type: 'exponential',
                delay: 1000,
            },
            delay: options.delay || 0,
            priority: options.priority || 0,
            removeOnComplete: { age: 3600 },
            removeOnFail: { age: 24 * 3600 },
        });

        res.status(201).json({
            id: job.id,
            type,
            status: 'queued'
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get job status
app.get('/api/jobs/:type/:id', async (req, res) => {
    try {
        const { type, id } = req.params;

        if (!queues[type]) {
            return res.status(400).json({ error: `Unknown job type: ${type}` });
        }

        const job = await queues[type].getJob(id);
        if (!job) {
            return res.status(404).json({ error: 'Job not found' });
        }

        const state = await job.getState();

        res.json({
            id: job.id,
            type,
            state,
            data: job.data,
            progress: job.progress,
            attemptsMade: job.attemptsMade,
            failedReason: job.failedReason,
            finishedOn: job.finishedOn,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Schedule recurring job
app.post('/api/jobs/schedule', async (req, res) => {
    try {
        const { type, data, cron } = req.body;

        if (!queues[type]) {
            return res.status(400).json({ error: `Unknown job type: ${type}` });
        }

        await queues[type].add(type, data, {
            repeat: { cron }
        });

        res.status(201).json({
            type,
            schedule: cron,
            status: 'scheduled'
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get queue stats
app.get('/api/queues/:type/stats', async (req, res) => {
    try {
        const { type } = req.params;

        if (!queues[type]) {
            return res.status(400).json({ error: `Unknown job type: ${type}` });
        }

        const [waiting, active, completed, failed] = await Promise.all([
            queues[type].getWaitingCount(),
            queues[type].getActiveCount(),
            queues[type].getCompletedCount(),
            queues[type].getFailedCount(),
        ]);

        res.json({
            queue: type,
            stats: { waiting, active, completed, failed }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Task Queue API running on port ${PORT}`));
