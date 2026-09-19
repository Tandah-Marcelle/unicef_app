import { Router } from 'express';
import { query } from '../db/pool.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();

// GET /api/stats/dashboard — Power BI friendly JSON analytics
router.get('/dashboard', authRequired, async (req, res, next) => {
  try {
    const [totals, followUpPhases, vulnerabilities, sessions, alerts, regions] =
      await Promise.all([
        query(`SELECT
          (SELECT COUNT(*) FROM families) AS total_families,
          (SELECT COUNT(*) FROM evaluations) AS total_evaluations,
          (SELECT COUNT(*) FROM group_sessions) AS total_sessions,
          (SELECT COUNT(*) FROM alerts) AS total_alerts,
          (SELECT COUNT(*) FROM alerts WHERE is_red_priority) AS red_alerts`),
        // Follow-up phase buckets mirror the app's FollowUpPhase logic:
        //   initial (<90d), consolidation (<180d), autonomy (<365d), longTerm (>=365d)
        query(`SELECT
          COUNT(*) FILTER (WHERE (now()::date - created_at) < 90)  AS initial,
          COUNT(*) FILTER (WHERE (now()::date - created_at) BETWEEN 90 AND 179) AS consolidation,
          COUNT(*) FILTER (WHERE (now()::date - created_at) BETWEEN 180 AND 364) AS autonomy,
          COUNT(*) FILTER (WHERE (now()::date - created_at) >= 365) AS long_term
          FROM families`),
        query(`SELECT vulnerability_status, COUNT(*) AS count
          FROM families GROUP BY vulnerability_status`),
        query(`SELECT
          COUNT(*) AS sessions,
          COALESCE(SUM(men_attendance), 0) AS men,
          COALESCE(SUM(women_attendance), 0) AS women,
          CASE WHEN COALESCE(SUM(men_attendance + women_attendance), 0) = 0
            THEN 0
            ELSE ROUND(100.0 * SUM(men_attendance) / SUM(men_attendance + women_attendance), 1)
          END AS positive_masculinity_index
          FROM group_sessions`),
        query(`SELECT risk_category, COUNT(*) AS count
          FROM alerts GROUP BY risk_category ORDER BY count DESC`),
        query(`SELECT COALESCE(region, 'Inconnue') AS region, COUNT(*) AS count
          FROM families GROUP BY region ORDER BY count DESC`),
      ]);

    res.json({
      generatedAt: new Date().toISOString(),
      totals: totals.rows[0],
      followUpPhases: followUpPhases.rows[0],
      vulnerabilities: vulnerabilities.rows,
      groupSessions: sessions.rows[0],
      alertsByCategory: alerts.rows,
      familiesByRegion: regions.rows,
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/stats/export — raw denormalized table for ETL into Power BI
router.get('/export', authRequired, async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT
        f.id              AS family_id,
        f.household_name,
        f.child_count,
        f.status          AS follow_up_status,
        f.neighborhood,
        f.phone_number,
        f.vulnerability_status,
        f.region,
        f.department,
        f.arrondissement,
        f.created_at      AS family_created_at,
        e.id              AS evaluation_id,
        e.visit_date,
        e.has_birth_certificate,
        e.has_children_with_disabilities,
        e.best_interest_understood,
        e.vaccinations_up_to_date,
        e.exclusive_breastfeeding,
        e.bed_nets_used,
        e.handwashing_with_soap,
        e.practices_budgeting,
        e.corporal_punishment_used,
        e.positive_reinforcement_used,
        e.visit_notes
      FROM families f
      LEFT JOIN evaluations e ON e.family_id = f.id
      ORDER BY f.created_at DESC, e.visit_date DESC
    `);
    res.json({ rows, count: rows.length });
  } catch (err) {
    next(err);
  }
});

export default router;