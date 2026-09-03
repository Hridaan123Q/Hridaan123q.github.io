const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// In-memory leaderboard storage
// Each entry: { name: "Player1", score: 100 }
let leaderboard = [
    { name: "HOKAGE", score: 9999 },
    { name: "KAKASHI", score: 5000 },
    { name: "IRUKA", score: 1000 }
];

// GET /api/leaderboard - Get top scores
app.get('/api/leaderboard', (req, res) => {
    // Return top 10 scores, sorted descending
    const sortedLeaderboard = [...leaderboard].sort((a, b) => b.score - a.score).slice(0, 10);
    res.json(sortedLeaderboard);
});

// POST /api/leaderboard - Save a new score
app.post('/api/leaderboard', (req, res) => {
    const { name, score } = req.body;

    if (!name || typeof score !== 'number') {
        return res.status(400).json({ error: "Invalid data format. Expected { name: string, score: number }" });
    }

    const playerName = name.substring(0, 10).toUpperCase(); // Limit length and uppercase for arcade feel

    leaderboard.push({ name: playerName, score });

    res.status(201).json({ message: "Score saved successfully." });
});

// Fallback to index.html for any other route
app.use( (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(port, () => {
    console.log(`Naruto Arcade Server running at http://localhost:${port}`);
});
