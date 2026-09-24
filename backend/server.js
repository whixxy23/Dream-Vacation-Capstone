const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const { pool, initSchema } = require('./db');

const app = express();
const port = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

const COUNTRIES_API_BASE_URL =
  process.env.COUNTRIES_API_BASE_URL ||
  'https://api.restcountries.com/countries/v5';

const COUNTRIES_API_KEY = process.env.COUNTRIES_API_KEY;

// Used by Docker healthchecks, CI smoke tests, and load balancer probes.
app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'ok', db: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'error', db: 'unreachable' });
  }
});

app.get('/api/destinations', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM destinations ORDER BY id DESC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/destinations', async (req, res) => {
  const { country } = req.body;

  if (!country || !country.trim()) {
    return res.status(400).json({ error: 'country is required' });
  }

  try {
    const response = await axios.get(`${COUNTRIES_API_BASE_URL}/names.common/${encodeURIComponent(country)}`, {
      params: {
        'api-key': COUNTRIES_API_KEY
      }
    });
    const countryInfo = response.data.data?.objects?.[0];

    if (!countryInfo) {
      return res.status(404).json({ error: `No country found matching "${country}"` });
    }

    const result = await pool.query(
      'INSERT INTO destinations (country, capital, population, region) VALUES ($1, $2, $3, $4) RETURNING *',
      [
        countryInfo.names?.common || country,
        countryInfo.capitals?.[0]?.name || null,
        countryInfo.population ?? null,
        countryInfo.region ?? null,
      ],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    if (err.response && err.response.status === 404) {
      return res.status(404).json({ error: `No country found matching "${country}"` });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/destinations/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM destinations WHERE id = $1', [id]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Only bind to a port (and touch the DB) when run directly, so `require`-ing
// this file from tests doesn't try to open a real connection or listener.
if (require.main === module) {
  initSchema()
    .then(() => {
      app.listen(port, () => {
        console.log(`Server running on port ${port}`);
      });
    })
    .catch((err) => {
      console.error('Failed to initialize database schema', err);
      process.exit(1);
    });
}

module.exports = app;
