const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const Redis = require('ioredis');
const { createAdapter } = require('@socket.io/redis-adapter');

const app = express();
const server = http.createServer(app);

// Redis for scaling
const pubClient = new Redis(process.env.REDIS_URL);
const subClient = pubClient.duplicate();

// Socket.IO with Redis adapter
const io = new Server(server, {
    cors: { origin: '*' },
    adapter: createAdapter(pubClient, subClient)
});

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI);

// Message schema
const MessageSchema = new mongoose.Schema({
    room: { type: String, required: true, index: true },
    sender: { type: String, required: true },
    content: String,
    type: { type: String, default: 'text' },
    createdAt: { type: Date, default: Date.now }
});
const Message = mongoose.model('Message', MessageSchema);

// Health check
app.get('/health', (req, res) => res.json({ status: 'healthy' }));

// Socket.IO events
io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    // Join room
    socket.on('join', async (room) => {
        socket.join(room);

        // Update presence in Redis
        await pubClient.sadd(`room:${room}:users`, socket.id);

        // Notify room
        socket.to(room).emit('user-joined', { id: socket.id, room });

        // Send message history
        const messages = await Message.find({ room })
            .sort({ createdAt: -1 })
            .limit(50)
            .lean();
        socket.emit('history', messages.reverse());
    });

    // Leave room
    socket.on('leave', async (room) => {
        socket.leave(room);
        await pubClient.srem(`room:${room}:users`, socket.id);
        socket.to(room).emit('user-left', { id: socket.id, room });
    });

    // Send message
    socket.on('message', async (data) => {
        const { room, content, sender } = data;

        // Save to database
        const message = await Message.create({
            room,
            sender,
            content,
            type: 'text'
        });

        // Broadcast to room
        io.to(room).emit('message', {
            id: message._id,
            room,
            sender,
            content,
            createdAt: message.createdAt
        });
    });

    // Typing indicator
    socket.on('typing', (data) => {
        socket.to(data.room).emit('typing', {
            user: data.user,
            isTyping: data.isTyping
        });
    });

    // Disconnect
    socket.on('disconnect', async () => {
        console.log(`User disconnected: ${socket.id}`);

        // Clean up presence
        const rooms = await pubClient.keys('room:*:users');
        for (const roomKey of rooms) {
            await pubClient.srem(roomKey, socket.id);
        }
    });
});

const PORT = process.env.PORT || 8000;
server.listen(PORT, () => console.log(`Chat server running on port ${PORT}`));
