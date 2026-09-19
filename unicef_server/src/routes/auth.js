import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { query } from '../db/pool.js';
import { verifyPin, signToken, toPublicFacilitator } from '../utils/helpers.js';
import { authRequired } from '../middleware/auth.js';
import { pickFields } from '../middleware/error.js';

const router = Router();

// POST /api/auth/login  — { identifier, pin }
// identifier = facilitator ID (MINPROFF-...) or phone number
router.post('/login', async (req, res, next) => {
  try {
    const { clean, errors } = pickFields(req.body, {
      identifier: { required: true },
      pin: { required: true },
    });
    if (errors.length) return res.status(400).json({ error: errors[0] });

    const { rows } = await query(
      `SELECT * FROM facilitators
       WHERE facilitator_id = $1 OR phone_number = $1`,
      [String(clean.identifier).trim()]
    );
    const facilitator = rows[0];
    if (!facilitator || !verifyPin(clean.pin, facilitator.pin_hash)) {
      return res.status(401).json({ error: 'Invalid facilitator ID or PIN' });
    }
    if (!facilitator.is_active) {
      return res.status(403).json({ error: 'Account is deactivated' });
    }

    await query('UPDATE facilitators SET last_login_at = now() WHERE id = $1', [facilitator.id]);

    const token = signToken(facilitator);
    res.json({
      token,
      expiresIn: 7 * 24 * 3600,
      user: toPublicFacilitator(facilitator),
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/auth/me — current session facilitator
router.get('/me', authRequired, (req, res) => {
  res.json({ user: toPublicFacilitator(req.facilitator) });
});

// POST /api/auth/change-pin — { currentPin, newPin }
router.post('/change-pin', authRequired, async (req, res, next) => {
  try {
    const { clean, errors } = pickFields(req.body, {
      currentPin: { required: true },
      newPin: { required: true },
    });
    if (errors.length) return res.status(400).json({ error: errors[0] });

    const { rows } = await query('SELECT pin_hash FROM facilitators WHERE id = $1', [
      req.facilitator.id,
    ]);
    if (!rows[0] || !verifyPin(clean.currentPin, rows[0].pin_hash)) {
      return res.status(401).json({ error: 'Current PIN is incorrect' });
    }
    if (!/^\d{4,6}$/.test(String(clean.newPin))) {
      return res.status(400).json({ error: 'New PIN must be 4-6 digits' });
    }

    const pinHash = await bcrypt.hash(String(clean.newPin), 10);
    await query('UPDATE facilitators SET pin_hash = $1 WHERE id = $2', [
      pinHash,
      req.facilitator.id,
    ]);
    res.json({ ok: true, message: 'PIN updated' });
  } catch (err) {
    next(err);
  }
});

export default router;