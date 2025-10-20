const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors()); // Zezwól na połączenia z Flutter

// Endpoint GET /points
app.get('/points', (req, res) => {
    res.json([
        { id: '1', name: 'Punkt A', lat: 52.2297, lng: 21.0122, order: 0 },
        { id: '2', name: 'Punkt B', lat: 52.2400, lng: 21.0200, order: 1 },
        { id: '3', name: 'Punkt C', lat: 52.2500, lng: 21.0300, order: 2 },
    ]);
});

app.listen(3000, () => {
    console.log('Backend działa na porcie 3000');
});