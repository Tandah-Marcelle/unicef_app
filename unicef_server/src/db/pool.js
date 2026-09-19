import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

const connectionString = process.env.DATABASE_URL;

export const pool = new Pool({
  connectionString,
  max: 10,
  idleTimeoutMillis: 30000,
});

pool.on('error', (err) => {
  console.error('[pg] unexpected error on idle client:', err.message);
});

export const query = (text, params) => pool.query(text, params);

export const checkConnection = async () => {
  const { rows } = await query('SELECT NOW() AS now');
  return rows[0].now;
};