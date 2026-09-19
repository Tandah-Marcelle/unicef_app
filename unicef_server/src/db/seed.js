import 'dotenv/config';
import { fileURLToPath } from 'node:url';
import bcrypt from 'bcryptjs';
import { pool } from './pool.js';
import { runMigrations } from './migrate.js';

const SEED_FACILITATORS = [
  {
    facilitatorId: 'MINPROFF-2024-0042',
    phoneNumber: '+237650000042',
    fullName: 'Marie Nguemo',
    role: 'Senior Field Facilitator',
    region: 'Extrême-Nord',
    district: 'Mora',
    pin: '1234',
  },
  {
    facilitatorId: 'MINPROFF-2024-0101',
    phoneNumber: '+237650000101',
    fullName: 'Paul Etoundi',
    role: 'Field Facilitator',
    region: 'Nord',
    district: 'Maroua',
    pin: '2468',
  },
];

async function seedFacilitator(f) {
  const pinHash = await bcrypt.hash(f.pin, 10);
  const { rowCount } = await pool.query(
    `INSERT INTO facilitators
       (facilitator_id, phone_number, full_name, role, region, district, pin_hash)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (facilitator_id) DO NOTHING`,
    [f.facilitatorId, f.phoneNumber, f.fullName, f.role, f.region, f.district, pinHash]
  );
  return rowCount;
}

async function seedDemoData() {
  // A demo family + evaluation so the dashboard/reports are not empty.
  const familyId = 'fam_demo_2024_0042';
  await pool.query(
    `INSERT INTO families
       (id, household_name, child_count, status, neighborhood, last_visit_date,
        phone_number, vulnerability_status, region, department, arrondissement)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     ON CONFLICT (id) DO NOTHING`,
    [familyId, 'Famille Moussa', 4, 'Full Follow-up', 'Kerawa', '2024-01-15',
     '+237650000042', 'Élevé', 'Extrême-Nord', 'Logone-et-Chari', 'Mora']
  );
}

export async function seed() {
  await runMigrations();

  let created = 0;
  for (const f of SEED_FACILITATORS) {
    const rowCount = await seedFacilitator(f);
    if (rowCount > 0) created += 1;
  }

  await seedDemoData();

  console.log(`[seed] ${created} facilitator(s) created (${SEED_FACILITATORS.length - created} already existed)`);
  console.log('[seed] demo family inserted');
  console.log('[seed] demo credentials ->');
  for (const f of SEED_FACILITATORS) {
    console.log(`         ${f.facilitatorId} / ${f.phoneNumber}  PIN: ${f.pin}`);
  }
}

const isDirectRun =
  process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];

if (isDirectRun) {
  seed()
    .then(async () => {
      await pool.end();
      process.exit(0);
    })
    .catch(async (err) => {
      console.error('[seed] failed:', err.message);
      await pool.end().catch(() => {});
      process.exit(1);
    });
}