const express = require('express');
const app = express();

const VERSION = process.env.VERSION || '1.0.0';
const COLOR = process.env.COLOR || 'unknown';

app.get('/', (req, res) => {
    res.json({
        version: VERSION,
        color: COLOR,
        hostname: require('os').hostname(),
        timestamp: new Date().toISOString()
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', version: VERSION });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`[${COLOR}] v${VERSION} running on port ${PORT}`);
});
