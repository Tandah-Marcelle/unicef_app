# ComMobi-Tracker API (unicef_server)

REST backend for the **ComMobi-Tracker** Flutter app (UNICEF / MINPROFF Cameroon).
Implements the `SQLite → API → PostgreSQL → Power BI` data pipeline described in the app's docs.

## Stack

- Node.js 18+ / Express
- PostgreSQL (via `pg`)
- JWT auth (PIN-based login for field facilitators)
- bcrypt PIN hashing

## Quick start

### 1. PostgreSQL

Create a database named `unicef_db`, then set your connection string in `.env`
(see `.env.example`). A ready-made `.env` is included.

### 2. Install & set up

```powershell
npm install
npm run db:setup    # runs migrate (schema) then seed (demo facilitators)
npm start           # starts on http://localhost:4000
```

Docker option (starts Postgres + API):

```powershell
docker compose up -d
```

### 3. Demo credentials

| Facilitator ID       | Phone            | PIN   |
| -------------------- | ---------------- | ----- |
| MINPROFF-2024-0042   | +237650000042    | 1234  |
| MINPROFF-2024-0101   | +237650000101    | 2468  |

## API reference

All routes below (except `POST /api/auth/login` and `/health`) require:
`Authorization: Bearer <token>`.

### Auth

| Method | Endpoint                | Body                                    | Description                  |
| ------ | ----------------------- | --------------------------------------- | ---------------------------- |
| POST   | `/api/auth/login`       | `{ identifier, pin }`                   | Login with facilitator ID or phone + PIN → JWT |
| GET    | `/api/auth/me`          | –                                       | Current facilitator          |
| POST   | `/api/auth/change-pin`  | `{ currentPin, newPin }`                | Rotate PIN (4–6 digits)      |

### Sync (used by the app's `synchronizeData()`)

| Method | Endpoint          | Body                                      | Description                          |
| ------ | ----------------- | ----------------------------------------- | ------------------------------------ |
| POST   | `/api/sync/push`  | `{ deviceId?, families?, evaluations?, groupSessions?, alerts? }` | Batch upsert of offline records in one transaction |
| GET    | `/api/sync/pull`  | `?since=ISO-timestamp`                    | Fetch all data (optionally since a time) |

Push payloads use the **same camelCase shapes** the app's SQLite models produce
(`Family`, `Evaluation`, `GroupSession`, `Alert`). After a successful push the
app flips its local `isSynced` flag to 1. The server stores the exact same
fields; booleans `0/1` are accepted for `isRedPriority` and the evaluation flags.

### Data reads

| Method | Endpoint                         | Description                        |
| ------ | -------------------------------- | ---------------------------------- |
| GET    | `/api/families`                  | All families                       |
| GET    | `/api/families/:id`              | One family                         |
| GET    | `/api/families/:id/evaluations`  | Evaluations for a family           |
| GET    | `/api/evaluations`               | All evaluations (`?familyId=` filter) |
| GET    | `/api/sessions`                  | All GSP group sessions             |
| GET    | `/api/alerts`                    | All safeguarding alerts            |
| GET    | `/api/profile`                   | Current facilitator profile        |
| PUT    | `/api/profile`                   | Update `region` / `district`       |

### Power BI pipeline

| Method | Endpoint               | Description                                        |
| ------ | ---------------------- | -------------------------------------------------- |
| GET    | `/api/stats/dashboard` | Aggregated JSON: totals, follow-up phase buckets, vulnerability, GSP Positive Masculinity Index, alerts by category, families by region |
| GET    | `/api/stats/export`    | Denormalized `families × evaluations` flat table for direct ETL |

### Health

`GET /health` — `{ ok, db }`; returns 503 if PostgreSQL is unreachable.

## Schema

Defined in `src/db/schema.sql`:

- `facilitators` — auth accounts (facilitator_id, phone, bcrypt PIN hash)
- `families` — households, follow-up status, GPS, admin hierarchy (region/department/arrondissement)
- `evaluations` — the 10-module checklist, `FOREIGN KEY → families`
- `group_sessions` — GSP workshops, attendance, Positive Masculinity Index inputs
- `alerts` — safeguarding alerts with anonymized description + red priority

Every synced table keeps `device_id` (origin) and `synced_at` timestamps so the
`/api/sync/pull?since=` incremental sync and Power BI `last_refresh` logic work.

## Project layout

```
unicef_server/
├── src/
│   ├── index.js            # Express app, route mounting, boot
│   ├── config.js           # env configuration
│   ├── db/
│   │   ├── pool.js         # pg connection pool
│   │   ├── schema.sql      # tables + indexes
│   │   ├── migrate.js      # applies schema
│   │   └── seed.js         # demo facilitators + demo family
│   ├── middleware/
│   │   ├── auth.js         # JWT verification
│   │   └── error.js        # 404 + error handler + field validation
│   ├── routes/
│   │   ├── auth.js         # login / me / change-pin
│   │   ├── profile.js      # facilitator profile
│   │   ├── sync.js         # push / pull
│   │   ├── families.js     # family reads
│   │   ├── evaluations.js  # evaluation reads
│   │   ├── sessions.js     # GSP session reads
│   │   ├── alerts.js       # alert reads
│   │   └── stats.js        # Power BI dashboard + export
│   └── utils/helpers.js    # token helpers, column maps, upsert builder
├── .env                    # local secrets (gitignored)
├── .env.example
├── docker-compose.yml
├── Dockerfile
└── package.json
```

## Next steps (wiring the Flutter app)

The app currently *simulates* sync in `lib/providers/app_state.dart`
(`synchronizeData()`, ~line 352) and login in `lib/screens/login_screen.dart`.
To go live:

1. Add `http` to the app's `pubspec.yaml`.
2. Create a `lib/services/api_client.dart` pointing at this server
   (`POST /api/auth/login`, `POST /api/sync/push`, `GET /api/sync/pull`).
3. Replace the login delay with a real call (respecting the offline toggle).
4. In `synchronizeData()`, POST the unsynced batches and only mark
   `isSynced = 1` on `{ ok: true }`.