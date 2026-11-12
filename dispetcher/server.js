const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.DISPATCHER_PORT || 3001;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Fallback to index.html for SPA-like navigation
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🎛️ SmartBus Dispetcher Web Dashboard http://localhost:${PORT} portda ishga tushdi!`);
});
