// api-gateway/index.js
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 3000;

// Get service URLs from environment variables (for AWS ECS) or use defaults
// NOTE: Public IP addresses are hardcoded below for quick testing purposes only.
// In production, these should be set via environment variables or service discovery.
// The hardcoded IPs will change when services are redeployed, so this is not a permanent solution.
const SERVICE1_URL = process.env.SERVICE1_URL || 'http://13.233.32.8:3001';
const SERVICE2_URL = process.env.SERVICE2_URL || 'http://35.154.157.110:3002';

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
