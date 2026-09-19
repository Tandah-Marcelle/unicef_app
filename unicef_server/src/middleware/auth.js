import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { query } from '../db/pool.js';

export async function authRequired(req, res, next) {
  try {
    const header = req.headers.authorization ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return res.status(401).json({ error: 'Missing Bearer token' });
    }

    const payload = jwt.verify(token, config.jwtSecret);
    const { rows } = await query(
      'SELECT id, facilitator_id, phone_number, full_name, role, region, district, is_active FROM facilitators WHERE id = $1',
      [payload.sub]
    );
    const facilitator = rows[0];
    if (!facilitator || !facilitator.is_active) {
      return res.status(401).json({ error: 'Facilitator not found or inactive' });
    }

    req.facilitator = facilitator;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}