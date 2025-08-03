// service1/index.js
const express = require('express');
const app = express();
const PORT = 3001; 

app.get('/message1', (req, res) => {
    console.log('Received a request for Service 1');
    res.send('Hello from Service 1!');
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Service 1 listening on http://0.0.0.0:${PORT}`);
});
