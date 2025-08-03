// api-gateway/index.js
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 3000;

// Get service URLs from environment variables (for AWS ECS) or use defaults
const SERVICE1_URL = process.env.SERVICE1_URL || 'http://service1:3001';
const SERVICE2_URL = process.env.SERVICE2_URL || 'http://service2:3002';

console.log('Service1 URL:', SERVICE1_URL);
console.log('Service2 URL:', SERVICE2_URL);

// Routing requests to Service 1
app.use('/service1', createProxyMiddleware({ 
    target: SERVICE1_URL, 
    changeOrigin: true,
    pathRewrite: { '^/service1': '' }, // Remove /service1 from the URL before proxying
    onError: (err, req, res) => {
        console.error('Proxy error for service1:', err.message);
        res.status(500).send('Service 1 is not available');
    }
})); 

// Routing requests to Service 2
app.use('/service2', createProxyMiddleware({ 
    target: SERVICE2_URL, 
    changeOrigin: true,
    pathRewrite: { '^/service2': '' },
    onError: (err, req, res) => {
        console.error('Proxy error for service2:', err.message);
        res.status(500).send('Service 2 is not available');
    }
}));

// API 1: /api/message1
app.get('/api/message1', (req, res) => {
    res.send('Hello from API 1!');
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service1_url: SERVICE1_URL,
        service2_url: SERVICE2_URL,
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`API Gateway listening on http://0.0.0.0:${PORT}`);
    console.log(`Service1 URL: ${SERVICE1_URL}`);
    console.log(`Service2 URL: ${SERVICE2_URL}`);
});
