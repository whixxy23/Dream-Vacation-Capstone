const { Pool } = require('pg');

// Single shared connection pool. DATABASE_URL is the standard Postgres
// connection string (postgres://user:pass@host:port/dbname), matching what
// docker-compose and most hosting providers (Render, RDS, etc.) expect.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

pool.on('error', (err) => {
  // eslint-disable-next-line no-console
  console.error('Unexpected PostgreSQL client error', err);
});

// The original app assumed a `destinations` table already existed with no
// migration or setup step anywhere in the repo. This creates it on boot if
// missing, so a fresh database (e.g. a brand new Docker volume, or CI's
// throwaway Postgres service) works without any manual step.
async function initSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS destinations (
      id SERIAL PRIMARY KEY,
      country VARCHAR(120) NOT NULL,
      capital VARCHAR(120),
      population BIGINT,
      region VARCHAR(120),
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

module.exports = { pool, initSchema };
