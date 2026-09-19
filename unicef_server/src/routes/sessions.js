import { Router } from 'express';
import { query } from '../db/pool.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();

// GET /api/sessions — all GSP group sessions
router.get('/', authRequired, async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT * FROM group_sessions ORDER BY session_date DESC`
    );
    res.json({ sessions: rows, count: rows.length });
  } catch (err) {
    next(err);
  }
});

export default router;