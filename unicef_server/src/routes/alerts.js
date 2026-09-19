import { Router } from 'express';
import { query } from '../db/pool.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();

// GET /api/alerts — safeguarding alerts, red priority first
router.get('/', authRequired, async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT * FROM alerts ORDER BY is_red_priority DESC, incident_date DESC`
    );
    res.json({ alerts: rows, count: rows.length });
  } catch (err) {
    next(err);
  }
});

export default router;