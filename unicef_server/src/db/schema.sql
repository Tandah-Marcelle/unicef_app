-- ComMobi-Tracker schema (mirrors the Flutter app's SQLite models)
-- Entities: facilitators, families, evaluations, group_sessions, alerts.

-- ── Facilitators (server-side auth accounts) ──────────────────────────────
CREATE TABLE IF NOT EXISTS facilitators (
  id            SERIAL PRIMARY KEY,
  facilitator_id TEXT UNIQUE NOT NULL,             -- e.g. MINPROFF-2024-0042
  phone_number  TEXT UNIQUE,
  full_name     TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'Field Facilitator',
  region        TEXT,
  district      TEXT,
  pin_hash      TEXT NOT NULL,                     -- bcrypt hash of the 4-6 digit PIN
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Families ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS families (
  id                 TEXT PRIMARY KEY,             -- client-generated: 'fam_<ts>_<rand>'
  household_name     TEXT NOT NULL,
  child_count        INTEGER NOT NULL DEFAULT 0,
  status             TEXT NOT NULL DEFAULT 'Partial Follow-up',
  neighborhood       TEXT NOT NULL,
  last_visit_date    TEXT,
  photo_proof_paths  TEXT,                         -- JSON-encoded list of client paths
  phone_number       TEXT,
  vulnerability_status TEXT NOT NULL DEFAULT 'Normal',  -- 'Normal' | 'Élevé' | 'Urgence'
  latitude           DOUBLE PRECISION,
  longitude          DOUBLE PRECISION,
  region             TEXT,
  department         TEXT,
  arrondissement     TEXT,
  created_at         DATE NOT NULL DEFAULT CURRENT_DATE,
  device_id          TEXT,                         -- originating device, set on push
  synced_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Evaluations (10-module checklist) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS evaluations (
  id                         TEXT PRIMARY KEY,     -- client-generated: 'eval_<ts>_<rand>'
  family_id                  TEXT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  has_birth_certificate      BOOLEAN NOT NULL DEFAULT FALSE,
  has_children_with_disabilities BOOLEAN NOT NULL DEFAULT FALSE,
  best_interest_understood   BOOLEAN NOT NULL DEFAULT FALSE,
  vaccinations_up_to_date    BOOLEAN NOT NULL DEFAULT FALSE,
  exclusive_breastfeeding    BOOLEAN NOT NULL DEFAULT FALSE,
  bed_nets_used              BOOLEAN NOT NULL DEFAULT FALSE,
  handwashing_with_soap      BOOLEAN NOT NULL DEFAULT FALSE,
  practices_budgeting        BOOLEAN NOT NULL DEFAULT FALSE,
  corporal_punishment_used   BOOLEAN NOT NULL DEFAULT FALSE,
  positive_reinforcement_used BOOLEAN NOT NULL DEFAULT FALSE,
  visit_notes                TEXT,
  visit_date                 DATE NOT NULL DEFAULT CURRENT_DATE,
  photo_proof_paths          TEXT,
  device_id                  TEXT,
  synced_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_evaluations_family ON evaluations(family_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_visit ON evaluations(visit_date DESC);

-- ── Group sessions (GSP workshops) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_sessions (
  id            TEXT PRIMARY KEY,                  -- client-generated: 'session_<ts>_<rand>'
  session_date  DATE NOT NULL,
  location      TEXT NOT NULL,
  men_attendance  INTEGER NOT NULL DEFAULT 0,
  women_attendance INTEGER NOT NULL DEFAULT 0,
  topic_covered TEXT NOT NULL,
  photo_proof_paths TEXT,
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  device_id     TEXT,
  synced_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Safeguarding alerts ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS alerts (
  id                     TEXT PRIMARY KEY,         -- client-generated: 'alert_<ts>_<rand>'
  risk_category          TEXT NOT NULL,
  anonymized_description TEXT NOT NULL,
  is_red_priority        BOOLEAN NOT NULL DEFAULT TRUE,
  incident_date          DATE NOT NULL DEFAULT CURRENT_DATE,
  latitude               DOUBLE PRECISION,
  longitude              DOUBLE PRECISION,
  device_id              TEXT,
  synced_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);