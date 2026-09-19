import { Router } from 'express';
import { pool } from '../db/pool.js';
import { authRequired } from '../middleware/auth.js';
import { buildUpsert } from '../utils/helpers.js';
import {
  familyColumnMap,
  evalColumnMap,
  sessionColumnMap,
  alertColumnMap,
} from '../utils/helpers.js';

const router = Router();

const GEO_COLS = ['latitude', 'longitude'];

// POST /api/sync/push
// Body: { deviceId?, families?: [], evaluations?: [], groupSessions?: [], alerts?: [] }
// Each item is a camelCase object (same shape the app's SQLite models produce).
// All rows are upserted in a single transaction and `synced_at` is refreshed,
// which is what lets the app flip its local isSynced flag to 1 afterwards.
router.post('/push', authRequired, async (req, res, next) => {
  const body = req.body ?? {};
  const deviceId = String(body.deviceId ?? `device-${req.facilitator.id}`);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const results = { families: 0, evaluations: 0, groupSessions: 0, alerts: 0 };

    const families = Array.isArray(body.families) ? body.families : [];
    if (families.length) {
      const { sql, params } = buildUpsert('families', families, familyColumnMap, [
        ...GEO_COLS,
        'device_id',
      ]);
      const { rowCount } = await client.query(sql, params);
      results.families = rowCount;
    }

    const evaluations = Array.isArray(body.evaluations) ? body.evaluations : [];
    if (evaluations.length) {
      const { sql, params } = buildUpsert('evaluations', evaluations, evalColumnMap, [
        'device_id',
      ]);
      const { rowCount } = await client.query(sql, params);
      results.evaluations = rowCount;
    }

    const groupSessions = Array.isArray(body.groupSessions) ? body.groupSessions : [];
    if (groupSessions.length) {
      const { sql, params } = buildUpsert(
        'group_sessions',
        groupSessions,
        sessionColumnMap,
        GEO_COLS.concat('device_id')
      );
      const { rowCount } = await client.query(sql, params);
      results.groupSessions = rowCount;
    }

    const alerts = Array.isArray(body.alerts) ? body.alerts : [];
    if (alerts.length) {
      const { sql, params } = buildUpsert('alerts', alerts, alertColumnMap, [
        ...GEO_COLS,
        'device_id',
      ]);
      const { rowCount } = await client.query(sql, params);
      results.alerts = rowCount;
    }

    await client.query('COMMIT');
    res.json({ ok: true, syncedAt: new Date().toISOString(), results });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// GET /api/sync/pull?since=ISO — fetch everything (optionally since a timestamp)
// Returns the data a fresh device needs to render its dashboard.
router.get('/pull', authRequired, async (req, res, next) => {
  try {
    const since = req.query.since ? String(req.query.since) : null;
    const sinceClause = since ? 'WHERE synced_at > $1' : '';
    const params = since ? [since] : [];

    const [families, evaluations, sessions, alerts] = await Promise.all([
      pool.query(
        `SELECT * FROM families ${sinceClause} ORDER BY created_at DESC`,
        params
      ),
      pool.query(
        `SELECT * FROM evaluations ${sinceClause} ORDER BY visit_date DESC`,
        params
      ),
      pool.query(
        `SELECT * FROM group_sessions ${sinceClause} ORDER BY session_date DESC`,
        params
      ),
      pool.query(
        `SELECT * FROM alerts ${sinceClause} ORDER BY incident_date DESC`,
        params
      ),
    ]);

    res.json({
      ok: true,
      serverTime: new Date().toISOString(),
      families: families.rows,
      evaluations: evaluations.rows,
      groupSessions: sessions.rows,
      alerts: alerts.rows,
    });
  } catch (err) {
    next(err);
  }
});

export default router;