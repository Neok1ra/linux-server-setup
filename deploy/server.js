const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;

// PostgreSQL connection
const { Client } = require('pg');

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'myapp',
  user: process.env.DB_USER || 'myapp_user',
  password: process.env.DB_PASSWORD || 'myapp_password',
};

// Health check endpoint
app.get('/health', (req, res) => {
  // Check database connectivity
  const client = new Client(dbConfig);
  
  client.connect()
    .then(() => {
      client.end();
      res.status(200).json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        database: 'Connected'
      });
    })
    .catch(err => {
      res.status(500).json({ 
        status: 'ERROR', 
        timestamp: new Date().toISOString(),
        database: 'Disconnected',
        error: err.message
      });
    });
});

// Main endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to the Sample Application',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Database test endpoint
app.get('/db-test', (req, res) => {
  const client = new Client(dbConfig);
  
  client.connect()
    .then(() => client.query('SELECT version()'))
    .then(result => {
      client.end();
      res.json({
        message: 'Database connection successful',
        version: result.rows[0].version,
        timestamp: new Date().toISOString()
      });
    })
    .catch(err => {
      res.status(500).json({
        message: 'Database connection failed',
        error: err.message,
        timestamp: new Date().toISOString()
      });
    });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  
  // Test database connection on startup
  const client = new Client(dbConfig);
  client.connect()
    .then(() => {
      console.log('Database connection successful');
      client.end();
    })
    .catch(err => {
      console.error('Database connection failed:', err.message);
    });
});

module.exports = app;