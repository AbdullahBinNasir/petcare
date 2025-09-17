const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from the Flutter web build directory
app.use(express.static(path.join(__dirname, 'build/web')));

// Handle client-side routing (SPA)
app.get('/*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build/web/index.html'));
});

app.listen(PORT, () => {
  console.log(`PetCare Web App is running on port ${PORT}`);
  console.log(`Visit: http://localhost:${PORT}`);
});
