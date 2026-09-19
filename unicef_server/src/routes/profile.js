import { Router } from 'express';
import { query } from '../db/pool.js';
import { authRequired } from '../middleware/auth.js';
import { toPublicFacilitator } from '../utils/helpers.js';

const router = Router();

// GET /api/profile — mirrors the app's local user_profile row shape
router.get('/', authRequired, async (req, res, next) => {
  try {
    res.json({ profile: toPublicFacilitator(req.facilitator) });
  } catch (err) {
    next(err);
  }
});

// PUT /api/profile — update region/district for this facilitator
router.put('/', authRequired, async (req, res, next) => {
  try {
    const body = req.body ?? {};
    const region = body.region ?? req.facilitator.region;
    const district = body.district ?? req.facilitator.district;

    const { rows } = await query(
      `UPDATE facilitators SET region = $1, district = $2
       WHERE id = $3 RETURNING *`,
      [region, district, req.facilitator.id]
    );
    res.json({ profile: toPublicFacilitator(rows[0]) });
  } catch (err) {
    next(err);
  }
});

export default router;