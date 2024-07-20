const express = require('express');
const cors = require('cors');
const redis = require('redis');
const app = express();
const port = 3010;

// Configure CORS options
const corsOptions = {
    origin: 'http://localhost:3000', // Allow all requests from your React app
    optionsSuccessStatus: 200 // For legacy browser support
};

// Apply CORS middleware
app.use(cors(corsOptions));

// Create a Redis client
const client = redis.createClient({
    url: 'redis://localhost:6379' // Default Redis URL
});
client.connect();

// Endpoint to get contract addresses from Redis
app.get('/api/contract-addresses', async (req, res) => {
    try {
        const data = await client.get('tiltui');
        if (data) {
            const addresses = JSON.parse(data); // Parse the JSON string from Redis
            res.json(addresses); // Send parsed JSON as response
        } else {
            res.status(404).send('No contract addresses found in Redis');
        }
    } catch (error) {
        console.error('Failed to fetch from Redis', error);
        res.status(500).send('Error fetching from Redis');
    }
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
