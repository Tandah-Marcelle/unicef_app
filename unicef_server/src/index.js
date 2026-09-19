import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { config } from './config.js';
import { checkConnection } from './db/pool.js';
import { notFound, errorHandler } from './middleware/error.js';

import authRoutes from './routes/auth.js';
import profileRoutes from './routes/profile.js';
import syncRoutes from './routes/sync.js';
import familyRoutes from './routes/families.js';
import evaluationRoutes from './routes/evaluations.js';
import sessionRoutes from './routes/sessions.js';
import alertRoutes from './routes/alerts.js';
import statsRoutes from './routes/stats.js';

const app = express();

app.use(cors({ origin: config.corsOrigin === '*' ? true : config.corsOrigin.split(',') }));
app.use(express.json({ limit: '10mb' }));

// Simple request logger
app.use((req, _res, next) => {
  console.log(`[api] ${req.method} ${req.originalUrl}`);
  next();
});

app.get('/health', async (_req, res) => {
  try {
    const now = await checkConnection();
    res.json({ ok: true, db: 'connected', time: now });
  } catch (err) {
    res.status(503).json({ ok: false, db: 'unreachable', error: err.message });
  }
});

app.get('/', (_req, res) => {
  res.json({
    name: 'ComMobi-Tracker API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth/login',
      me: '/api/auth/me',
      profile: '/api/profile',
      syncPush: 'POST /api/sync/push',
      syncPull: 'GET /api/sync/pull',
      families: '/api/families',
      evaluations: '/api/evaluations',
      sessions: '/api/sessions',
      alerts: '/api/alerts',
      stats: '/api/stats/dashboard',
      export: '/api/stats/export',
      health: '/health',
    },
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/families', familyRoutes);
app.use('/api/evaluations', evaluationRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/stats', statsRoutes);

app.use(notFound);
app.use(errorHandler);

async function start() {
  try {
    await checkConnection();
    console.log('[db] PostgreSQL connected');
  } catch (err) {
    console.warn(
      `[db] PostgreSQL unreachable (${err.message}). ` +
        'Start Postgres (docker compose up -d) and run `npm run db:setup`.'
    );
  }

  app.listen(config.port, () => {
    console.log(`[server] ComMobi-Tracker API listening on http://localhost:${config.port}`);
  });
}

start();