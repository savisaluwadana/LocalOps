const express = require('express');
const app = express();

const COLOR = process.env.APP_COLOR || 'unknown';
const VERSION = process.env.APP_VERSION || '0.0.0';

app.get('/', (req, res) => {
    res.json({
        environment: COLOR,
        version: VERSION,
        timestamp: new Date().toISOString(),
        hostname: require('os').hostname()
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', color: COLOR, version: VERSION });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`[${COLOR.toUpperCase()}] App v${VERSION} running on port ${PORT}`);
});
