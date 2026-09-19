import 'dotenv/config';
import { fileURLToPath } from 'node:url';
import { pool } from './pool.js';
import { runMigrations } from './migrate.js';

// ── Realistic Cameroonian reference data ────────────────────────────────────

const REGION_CENTROIDS = {
  'Extrême-Nord': [11.5, 14.3],
  Nord: [9.3, 13.4],
  Adamaoua: [7.32, 13.58],
  Centre: [3.87, 11.52],
  Est: [4.58, 13.77],
  Littoral: [4.05, 9.7],
  'Nord-Ouest': [5.96, 10.15],
  Ouest: [5.48, 10.42],
  Sud: [2.9, 11.15],
  'Sud-Ouest': [4.15, 9.24],
};

const ADMIN_HIERARCHY = {
  'Extrême-Nord': {
    Diamaré: ['Maroua 1er', 'Maroua 2ème', 'Maroua 3ème', 'Bogo', 'Gazawa', 'Méri'],
    'Logone-et-Chari': ['Kousseri', 'Blangoua', 'Fotokol', 'Makary', 'Waza'],
    'Mayo-Danay': ['Yagoua', 'Datchéka', 'Guémé', 'Maga', 'Vélé'],
    'Mayo-Kani': ['Kaélé', 'Mindif', 'Moulvoudaye'],
    'Mayo-Mosogo': ['Hina', 'Koza', 'Tokombéré'],
    'Mayo-Sava': ['Mora', 'Kolofata', 'Méri'],
    'Mayo-Tsanaga': ['Mokolo', 'Bourha', 'Mogodé', 'Touloum'],
  },
  Nord: {
    Bénoué: ['Garoua 1er', 'Garoua 2ème', 'Bibemi', 'Lagdo'],
    Faro: ['Poli', 'Beka'],
    'Mayo-Louti': ['Guider', 'Figuil', 'Mayo-Oulo'],
    'Mayo-Rey': ['Rey-Bouba', 'Tcholliré', 'Touboro'],
  },
  Adamaoua: {
    Djérem: ['Tibati', 'Ngaoundal'],
    'Mayo-Banyo': ['Banyo', 'Bankim'],
    Mbéré: ['Meiganga', 'Djohong'],
    Vina: ['Ngaoundéré 1er', 'Ngaoundéré 2ème', 'Belel', 'Martap'],
  },
  Centre: {
    Lékié: ['Monatélé', "Sa'a", 'Obala'],
    Mfoundi: ['Yaoundé 1er', 'Yaoundé 2ème', 'Yaoundé 3ème', 'Yaoundé 5ème'],
    'Mbam-et-Inoubou': ['Bafia', 'Makénéné'],
    'Nyong-et-Kellé': ['Eséka', 'Makak'],
  },
  Est: {
    'Lom-et-Djerem': ['Bertoua 1er', 'Bélabo'],
    Kadey: ['Batouri', 'Kette'],
    'Haut-Nyong': ['Abong-Mbang', 'Doumé'],
  },
  Littoral: {
    Wouri: ['Douala 1er', 'Douala 2ème', 'Douala 3ème', 'Douala 5ème'],
    Moungo: ['Nkongsamba 1er', 'Loum', 'Mbanga', 'Melong'],
    'Sanaga-Maritime': ['Edéa 1er', 'Dizangue', 'Pouma'],
  },
  'Nord-Ouest': {
    Mezam: ['Bamenda 1er', 'Bamenda 2ème', 'Bamenda 3ème'],
    Bui: ['Kumbo', 'Jakiri'],
    Menchum: ['Wum', 'Fungom'],
    Donga: ['Nkambe', 'Ako'],
  },
  Ouest: {
    Mifi: ['Bafoussam 1er', 'Bafoussam 2ème'],
    Menoua: ['Dschang', 'Fokoué', 'Santchou'],
    Noun: ['Foumban', 'Foumbot', 'Koutaba'],
    Bamboutos: ['Mbouda', 'Batcham'],
  },
  Sud: {
    'Dja-et-Lobo': ['Sangmélima', 'Djoum'],
    Mvila: ['Ebolowa 1er', 'Mvangan'],
    Océan: ['Kribi 1er', 'Campo'],
  },
  'Sud-Ouest': {
    Fako: ['Buea', 'Limbe 1er', 'Muyuka', 'Tiko'],
    Meme: ['Kumba 1er', 'Konye', 'Mbonge'],
    Manyu: ['Mamfe', 'Akwaya'],
  },
};

const FIRST_NAMES_MASC = [
  'Moussa', 'Abakar', 'Mahamat', 'Djibril', 'Ousmane', 'Bouba', 'Yaya',
  'Alioum', 'Idrissou', 'Sadou', 'Hamidou', 'Souleymane', 'Amadou', 'Bello',
  'Jean', 'Emmanuel', 'Étienne', 'Blaise', 'Célestin', 'Roger', 'Joseph',
  'Ndifor', 'Fotso', 'Kamga', 'Mbarga', 'Etoundi', 'Tabi', 'Ngassa',
];
const FIRST_NAMES_FEM = [
  'Fadimatou', 'Aïssatou', 'Hawa', 'Zara', 'Mariam', 'Ramatou', 'Halima',
  'Yacoubou', 'Fatimé', 'Adja', 'Marie', 'Bernadette', 'Solange', 'Estelle',
  'Chantal', 'Adèle', 'Françoise', 'Delphine', 'Nadège', 'Clarisse',
];
const LAST_NAMES = [
  'Moussa', 'Aboubakar', 'Alioum', 'Bakari', 'Hamadou', 'Issa', 'Kaigama',
  'Liman', 'Madou', 'Ndjidda', 'Oumarou', 'Sali', 'Tchouta', 'Wabi',
  'Nguemo', 'Etoundi', 'Mbarga', 'Onana', 'Fotso', 'Tchana', 'Njoya',
  'Kemayou', 'Biya', 'Manga', 'Bell', 'Ewane', 'Njie', 'Ayissi', 'Mballa',
];
const HOUSEHOLD_PREFIXES = ['Famille'];

const TOPICS = [
  'Enregistrement des naissances et état civil',
  "Intérêt supérieur de l'enfant",
  'Les 1000 premiers jours',
  'Hygiène et assainissement (WASH)',
  'Budget familial et planification',
  'Discipline positive sans violence',
  'Communication parents-enfants',
  'Éducation inclusive des filles',
  'Prévention du mariage précoce',
  'Engagement paternel et masculinité positive',
];

const RISK_CATEGORIES = [
  'Abus physique',
  'Mariage précoce',
  'Travail des enfants',
  'Négligence',
  'Violence basée sur le genre',
  'Traite des enfants',
  'Malnutrition sévère',
];

const VULNERABILITY_LEVELS = ['Normal', 'Normal', 'Normal', 'Élevé', 'Urgence'];
const FOLLOW_UP_STATUSES = ['Full Follow-up', 'Partial Follow-up', 'Partial Follow-up'];

// ── Deterministic RNG (mulberry32) ──────────────────────────────────────────
function rng(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick(rand, arr) {
  return arr[Math.floor(rand() * arr.length)];
}

function pickRegion(rand) {
  const r = rand();
  if (r < 0.40) return 'Extrême-Nord';
  if (r < 0.60) return 'Nord';
  if (r < 0.70) return 'Adamaoua';
  if (r < 0.80) return 'Extrême-Nord'; // double weight stays in zone
  const rest = Object.keys(REGION_CENTROIDS).filter(
    (k) => !['Extrême-Nord', 'Nord'].includes(k)
  );
  return pick(rand, rest);
}

function pickAdminPlace(rand, region) {
  const departments = ADMIN_HIERARCHY[region] ?? {};
  const deptKeys = Object.keys(departments);
  if (!deptKeys.length) return { department: null, arrondissement: null };
  const department = pick(rand, deptKeys);
  const arrondissements = departments[department];
  return { department, arrondissement: pick(rand, arrondissements) };
}

function isoDateDaysAgo(rand, minDays, maxDays) {
  const days = minDays + Math.floor(rand() * (maxDays - minDays));
  const d = new Date(Date.now() - days * 86400000);
  return d.toISOString().substring(0, 10);
}

// ── Generators ──────────────────────────────────────────────────────────────

function generateFamilies(n, rand) {
  const families = [];
  for (let i = 0; i < n; i++) {
    const region = pickRegion(rand);
    const { department, arrondissement } = pickAdminPlace(rand, region);
    const centroid = REGION_CENTROIDS[region] ?? [5.0, 12.0];
    const latitude = +(centroid[0] + (rand() - 0.5) * 1.2).toFixed(6);
    const longitude = +(centroid[1] + (rand() - 0.5) * 1.2).toFixed(6);

    const masc = rand() < 0.55;
    const firstName = masc ? pick(rand, FIRST_NAMES_MASC) : pick(rand, FIRST_NAMES_FEM);
    const lastName = pick(rand, LAST_NAMES);
    const createdAt = isoDateDaysAgo(rand, 5, 700);

    families.push({
      id: `fam_fake_${String(i + 1).padStart(5, '0')}`,
      household_name: `${pick(rand, HOUSEHOLD_PREFIXES)} ${firstName} ${lastName}`,
      child_count: 1 + Math.floor(rand() * 8),
      status: pick(rand, FOLLOW_UP_STATUSES),
      neighborhood: arrondissement ?? 'Non précisé',
      last_visit_date: isoDateDaysAgo(rand, 0, 120),
      photo_proof_paths: null,
      phone_number: `+2376${Math.floor(10000000 + rand() * 89999999)}`,
      vulnerability_status: pick(rand, VULNERABILITY_LEVELS),
      latitude,
      longitude,
      region,
      department,
      arrondissement,
      created_at: createdAt,
      device_id: `device-${1 + Math.floor(rand() * 25)}`,
    });
  }
  return families;
}

function generateEvaluations(families, rand) {
  // One evaluation per family, dated after family registration.
  return families.map((f) => ({
    id: `eval_fake_${f.id.replace('fam_fake_', '')}`,
    family_id: f.id,
    has_birth_certificate: rand() < 0.72,
    has_children_with_disabilities: rand() < 0.08,
    best_interest_understood: rand() < 0.65,
    vaccinations_up_to_date: rand() < 0.68,
    exclusive_breastfeeding: rand() < 0.60,
    bed_nets_used: rand() < 0.75,
    handwashing_with_soap: rand() < 0.55,
    practices_budgeting: rand() < 0.48,
    corporal_punishment_used: rand() < 0.35,
    positive_reinforcement_used: rand() < 0.62,
    visit_notes: pick(rand, [
      'Visite standard, famille coopérative.',
      'Suivi nutritionnel requis pour le dernier-né.',
      'Père impliqué dans les tâches domestiques.',
      'Documents délivrés après sensibilisation.',
      'Besoin de moustiquaires supplémentaires.',
      'Session de rappel sur la discipline positive.',
      'Famille en situation de vulnérabilité accrue.',
      '',
    ]),
    visit_date: f.last_visit_date,
    photo_proof_paths: null,
    device_id: f.device_id,
  }));
}

function generateGroupSessions(n, rand) {
  const sessions = [];
  for (let i = 0; i < n; i++) {
    const region = pickRegion(rand);
    const { arrondissement } = pickAdminPlace(rand, region);
    const centroid = REGION_CENTROIDS[region] ?? [5.0, 12.0];
    const men = 3 + Math.floor(rand() * 22);
    const women = 4 + Math.floor(rand() * 30);
    sessions.push({
      id: `session_fake_${String(i + 1).padStart(5, '0')}`,
      session_date: isoDateDaysAgo(rand, 1, 365),
      location: `${arrondissement ?? region} - ${pick(rand, ['Centre communautaire', 'École publique', 'Marché central', 'Case de quartier', 'Mosquée', 'Église'])}`,
      men_attendance: men,
      women_attendance: women,
      topic_covered: pick(rand, TOPICS),
      photo_proof_paths: null,
      latitude: +(centroid[0] + (rand() - 0.5) * 1.2).toFixed(6),
      longitude: +(centroid[1] + (rand() - 0.5) * 1.2).toFixed(6),
      device_id: `device-${1 + Math.floor(rand() * 25)}`,
    });
  }
  return sessions;
}

function generateAlerts(n, rand) {
  const alerts = [];
  for (let i = 0; i < n; i++) {
    const region = pickRegion(rand);
    const centroid = REGION_CENTROIDS[region] ?? [5.0, 12.0];
    alerts.push({
      id: `alert_fake_${String(i + 1).padStart(5, '0')}`,
      risk_category: pick(rand, RISK_CATEGORIES),
      anonymized_description: pick(rand, [
        'Signalement anonyme transmis par un voisin, vérification en cours.',
        'Cas signalé par un enseignant lors de la session communautaire.',
        'Alerte anonyme via ligne verte, enfant apparentement en danger.',
        'Signalement recueilli auprès des leaders communautaires.',
        'Cas détecté durant une visite de suivi à domicile.',
        'Plainte anonyme déposée au centre de santé du quartier.',
      ]),
      is_red_priority: rand() < 0.45,
      incident_date: isoDateDaysAgo(rand, 0, 180),
      latitude: +(centroid[0] + (rand() - 0.5) * 1.2).toFixed(6),
      longitude: +(centroid[1] + (rand() - 0.5) * 1.2).toFixed(6),
      device_id: `device-${1 + Math.floor(rand() * 25)}`,
    });
  }
  return alerts;
}

// ── Batched inserts ─────────────────────────────────────────────────────────

async function batchInsert(table, columns, rows, batchSize = 250) {
  let inserted = 0;
  for (let start = 0; start < rows.length; start += batchSize) {
    const batch = rows.slice(start, start + batchSize);
    const values = [];
    const params = [];
    let p = 1;
    for (const row of batch) {
      const placeholders = columns.map(() => `$${p++}`);
      params.push(...columns.map((c) => row[c] ?? null));
      values.push(`(${placeholders.join(', ')})`);
    }
    await pool.query(
      `INSERT INTO ${table} (${columns.join(', ')}) VALUES ${values.join(', ')}
       ON CONFLICT (id) DO NOTHING`,
      params
    );
    inserted += batch.length;
  }
  return inserted;
}

export async function seedFakeData({ families = 1000, sessions = 1000, alerts = 1000 } = {}) {
  await runMigrations();

  console.log('[fake] clearing existing demo/test rows...');
  await pool.query('TRUNCATE evaluations, families, group_sessions, alerts RESTART IDENTITY CASCADE');

  const rand = rng(20260820);

  console.log('[fake] generating families...');
  const fams = generateFamilies(families, rand);
  await batchInsert('families', Object.keys(fams[0]), fams);

  console.log('[fake] generating evaluations...');
  const evals = generateEvaluations(fams, rand);
  await batchInsert('evaluations', Object.keys(evals[0]), evals);

  console.log('[fake] generating group sessions...');
  const sess = generateGroupSessions(sessions, rand);
  await batchInsert('group_sessions', Object.keys(sess[0]), sess);

  console.log('[fake] generating alerts...');
  const alts = generateAlerts(alerts, rand);
  await batchInsert('alerts', Object.keys(alts[0]), alts);

  const counts = await pool.query(`SELECT
    (SELECT COUNT(*) FROM families) AS families,
    (SELECT COUNT(*) FROM evaluations) AS evaluations,
    (SELECT COUNT(*) FROM group_sessions) AS group_sessions,
    (SELECT COUNT(*) FROM alerts) AS alerts`);
  console.log('[fake] done:', counts.rows[0]);
}

const isDirectRun =
  process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];

if (isDirectRun) {
  seedFakeData()
    .then(async () => {
      await pool.end();
      process.exit(0);
    })
    .catch(async (err) => {
      console.error('[fake] failed:', err.message);
      await pool.end().catch(() => {});
      process.exit(1);
    });
}