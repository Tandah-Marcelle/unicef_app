import { Router } from 'express';
import { query } from '../db/pool.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();

// GET /api/families — all families (newest synced first)
router.get('/', authRequired, async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT * FROM families ORDER BY created_at DESC, synced_at DESC`
    );
    res.json({ families: rows, count: rows.length });
  } catch (err) {
    next(err);
  }
});

// GET /api/families/:id
router.get('/:id', authRequired, async (req, res, next) => {
  try {
    const { rows } = await query('SELECT * FROM families WHERE id = $1', [req.params.id]);
    if (!rows[0]) return res.status(404).json({ error: 'Family not found' });
    res.json({ family: rows[0] });
  } catch (err) {
    next(err);
  }
});

// GET /api/families/:id/evaluations
router.get('/:id/evaluations', authRequired, async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT * FROM evaluations WHERE family_id = $1 ORDER BY visit_date DESC`,
      [req.params.id]
    );
    res.json({ evaluations: rows, count: rows.length });
  } catch (err) {
    next(err);
  }
});

export default router;