const express = require('express');
const mongoose = require('mongoose');
const axios = require('axios');

const app = express();
app.use(express.json());

mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/orders');

const USER_SERVICE = process.env.USER_SERVICE_URL || 'http://localhost:3001';
const PRODUCT_SERVICE = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002';

const orderSchema = new mongoose.Schema({
    userId: { type: String, required: true },
    productId: { type: String, required: true },
    quantity: { type: Number, required: true },
    status: { type: String, default: 'pending' },
    createdAt: { type: Date, default: Date.now }
});

const Order = mongoose.model('Order', orderSchema);

app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'order-service' });
});

app.get('/orders', async (req, res) => {
    try {
        const orders = await Order.find().limit(100);
        res.json(orders);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/orders/:id', async (req, res) => {
    try {
        const order = await Order.findById(req.params.id);
        if (!order) return res.status(404).json({ error: 'Order not found' });

        // Enrich with user and product data
        const [userRes, productRes] = await Promise.all([
            axios.get(`${USER_SERVICE}/users/${order.userId}`).catch(() => null),
            axios.get(`${PRODUCT_SERVICE}/products/${order.productId}`).catch(() => null)
        ]);

        res.json({
            ...order.toObject(),
            user: userRes?.data || null,
            product: productRes?.data || null
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/orders', async (req, res) => {
    try {
        const { userId, productId, quantity } = req.body;

        // Validate user exists
        const userRes = await axios.get(`${USER_SERVICE}/users/${userId}`);
        if (!userRes.data) {
            return res.status(400).json({ error: 'User not found' });
        }

        // Validate product exists
        const productRes = await axios.get(`${PRODUCT_SERVICE}/products/${productId}`);
        if (!productRes.data) {
            return res.status(400).json({ error: 'Product not found' });
        }

        const order = new Order({ userId, productId, quantity });
        await order.save();

        res.status(201).json({
            ...order.toObject(),
            user: userRes.data,
            product: productRes.data
        });
    } catch (err) {
        if (err.response?.status === 404) {
            return res.status(400).json({ error: 'User or Product not found' });
        }
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
    console.log(`Order Service running on port ${PORT}`);
});
