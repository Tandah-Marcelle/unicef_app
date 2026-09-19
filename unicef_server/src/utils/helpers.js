import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { config } from '../config.js';

export function verifyPin(pin, pinHash) {
  return bcrypt.compareSync(String(pin), pinHash);
}

export function signToken(facilitator) {
  return jwt.sign(
    {
      sub: facilitator.id,
      facilitatorId: facilitator.facilitator_id,
      role: facilitator.role,
    },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn }
  );
}

export function toPublicFacilitator(row) {
  return {
    id: row.id,
    facilitatorId: row.facilitator_id,
    phoneNumber: row.phone_number,
    fullName: row.full_name,
    role: row.role,
    region: row.region,
    district: row.district,
  };
}

// Column-name mapping used to translate camelCase API payloads
// into snake_case DB columns and back.
export const familyColumnMap = {
  householdName: 'household_name',
  childCount: 'child_count',
  status: 'status',
  neighborhood: 'neighborhood',
  lastVisitDate: 'last_visit_date',
  photoProofPaths: 'photo_proof_paths',
  phoneNumber: 'phone_number',
  vulnerabilityStatus: 'vulnerability_status',
  region: 'region',
  department: 'department',
  arrondissement: 'arrondissement',
  createdAt: 'created_at',
};

export const evalColumnMap = {
  familyId: 'family_id',
  hasBirthCertificate: 'has_birth_certificate',
  hasChildrenWithDisabilities: 'has_children_with_disabilities',
  bestInterestUnderstood: 'best_interest_understood',
  vaccinationsUpToDate: 'vaccinations_up_to_date',
  exclusiveBreastfeeding: 'exclusive_breastfeeding',
  bedNetsUsed: 'bed_nets_used',
  handwashingWithSoap: 'handwashing_with_soap',
  practicesBudgeting: 'practices_budgeting',
  corporalPunishmentUsed: 'corporal_punishment_used',
  positiveReinforcementUsed: 'positive_reinforcement_used',
  visitNotes: 'visit_notes',
  visitDate: 'visit_date',
  photoProofPaths: 'photo_proof_paths',
};

export const sessionColumnMap = {
  sessionDate: 'session_date',
  location: 'location',
  menAttendance: 'men_attendance',
  womenAttendance: 'women_attendance',
  topicCovered: 'topic_covered',
  photoProofPaths: 'photo_proof_paths',
};

export const alertColumnMap = {
  riskCategory: 'risk_category',
  anonymizedDescription: 'anonymized_description',
  isRedPriority: 'is_red_priority',
  incidentDate: 'incident_date',
};

// Returns SQL `col = $n` pairs for an upsert's ON CONFLICT DO UPDATE clause.
export function conflictUpdatePairs(columnMap, offset) {
  const pairs = [];
  let i = offset;
  for (const col of Object.values(columnMap)) {
    pairs.push(`${col} = $${i}`);
    i += 1;
  }
  return { pairs: pairs.join(', '), nextIndex: i };
}

// Columns that hold DATE values — empty strings from offline clients must
// become NULL or PostgreSQL rejects the cast.
const DATE_COLUMNS = new Set([
  'created_at',
  'last_visit_date',
  'visit_date',
  'session_date',
  'incident_date',
]);

// Builds a single multi-row upsert statement.
//   rows        : array of camelCase payload objects, each with an `id`
//   columnMap   : camelCase key -> DB column (non-id fields)
//   extraColumns: additional DB columns filled from matching camelCase row keys
export function buildUpsert(table, rows, columnMap, extraColumns = []) {
  const dbCols = ['id', ...extraColumns, ...Object.values(columnMap)];
  const camelByCol = {};
  for (const [camel, col] of Object.entries(columnMap)) camelByCol[col] = camel;

  const valueGroups = [];
  const params = [];
  let p = 1;

  for (const row of rows) {
    const placeholders = [];
    for (const col of dbCols) {
      let value;
      if (col === 'id') value = row.id;
      else if (camelByCol[col]) value = row[camelByCol[col]] ?? null;
      else value = row[col] ?? null; // extraColumns keyed by DB name == camelCase
      if (DATE_COLUMNS.has(col) && value === '') value = null;
      placeholders.push(`$${p++}`);
      params.push(value);
    }
    valueGroups.push(`(${placeholders.join(', ')})`);
  }

  const updateSet = dbCols
    .filter((c) => c !== 'id')
    .map((c) => `${c} = EXCLUDED.${c}`)
    .join(', ');

  const sql = `INSERT INTO ${table} (${dbCols.join(', ')})
    VALUES ${valueGroups.join(', ')}
    ON CONFLICT (id) DO UPDATE SET ${updateSet}`;

  return { sql, params };
}