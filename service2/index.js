// service2/index.js
const express = require('express');
const app = express();
const PORT = 3002;

app.get('/message2', (req, res) => {
    console.log('Received a request for Service 2');
    res.send('Greetings from Service 2!');
});

app.listen(PORT, () => {
    console.log(`Service 2 listening on http://localhost:${PORT}`);
});
