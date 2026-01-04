const express = require('express');
const app = express();

const VERSION = process.env.VERSION || '1.0.0';
const BUILD_DATE = process.env.BUILD_DATE || new Date().toISOString();

app.get('/', (req, res) => {
    res.json({
        name: 'demo-app',
        version: VERSION,
        buildDate: BUILD_DATE
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

module.exports = app;
