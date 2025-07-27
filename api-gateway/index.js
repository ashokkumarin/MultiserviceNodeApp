// api-gateway/index.js
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 3000;

// Routing requests to Service 1
app.use('/service1', createProxyMiddleware({ 
    target: 'http://service1:3001', 
    changeOrigin: true,
    pathRewrite: { '^/service1': '' } // Remove /service1 from the URL before proxying
})); 

// Routing requests to Service 2
app.use('/service2', createProxyMiddleware({ 
    target: 'http://service2:3002', 
    changeOrigin: true,
    pathRewrite: { '^/service2': '' } 
}));

// API 1: /api/message1
app.get('/api/message1', (req, res) => {
    res.send('Hello from API 1!');
  });

app.listen(PORT, () => {
    console.log(`API Gateway listening on http://localhost:${PORT}`);
});
