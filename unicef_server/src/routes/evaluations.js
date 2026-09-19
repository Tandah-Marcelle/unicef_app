import { Router } from 'express';
import { query } from '../db/pool.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();

// GET /api/evaluations — optionally filter by ?familyId=
router.get('/', authRequired, async (req, res, next) => {
  try {
    const where = req.query.familyId ? 'WHERE family_id = $1' : '';
    const params = req.query.familyId ? [req.query.familyId] : [];
    const { rows } = await query(
      `SELECT * FROM evaluations ${where} ORDER BY visit_date DESC`,
      params
    );
    res.json({ evaluations: rows, count: rows.length });
  } catch (err) {
    next(err);
  }
});

export default router;