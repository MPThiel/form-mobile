# FORM Server

Node 20 + Fastify + TypeScript + Prisma. Backend for the FORM mobile app.

## Quick start

```sh
cp .env.example .env
npm install
npm run prisma:generate
# Need a running Postgres for migrations:
npm run prisma:migrate
npm run dev
```

`GET http://localhost:3000/health` → `{ "status": "ok" }`.

## Scripts

| Script | What it does |
|---|---|
| `npm run dev` | Watch mode (`tsx watch`) |
| `npm run build` | `tsc` to `dist/` |
| `npm run start` | Run compiled `dist/index.js` |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run lint` | ESLint over `src/` and `test/` |
| `npm run test` | Vitest |
| `npm run prisma:generate` | Generate Prisma client |
| `npm run prisma:migrate` | Dev migration (creates SQL + applies) |
| `npm run prisma:validate` | Validate schema only — used in CI |

## Layout

See [CLAUDE.md](../CLAUDE.md) for the canonical folder description. Briefly:

```
src/
├── index.ts         Entrypoint — boots the app and listens
├── app.ts           Fastify factory (used by tests too via `inject`)
├── plugins/         auth, prisma, errorHandler
├── routes/          One file per resource (only health.ts in Phase 0)
├── services/        Third-party API wrappers (Claude, Strava, R2, coachPrompt)
└── lib/             Internal helpers (crypto)

prisma/schema.prisma Data model — see spec section 4
test/                Vitest suites
```

## Deploy (Railway)

The repo deploys from this `server/` subdirectory. In the Railway service settings set **Root Directory** to `server` so `railway.json` and the `Dockerfile` resolve correctly.

```sh
# One-time, from server/:
railway login
railway link                  # link to the FORM project (create it in the dashboard first)

# Add a Postgres plugin in the dashboard — it injects DATABASE_URL automatically.
# Set the remaining secrets (never commit these):
railway variables set \
  SUPABASE_PROJECT_URL=... \
  SUPABASE_AUDIENCE=authenticated \
  SUPABASE_SERVICE_ROLE_KEY=... \
  ANTHROPIC_API_KEY=... \
  STRAVA_CLIENT_ID=... STRAVA_CLIENT_SECRET=...

railway up                    # build + deploy via the Dockerfile
```

> **Required before deploying:** `SUPABASE_SERVICE_ROLE_KEY` must be set in the
> Railway service variables. It is the `service_role` (secret) key from
> Supabase → Project Settings → API, used server-side to send magic-link emails
> via `POST /auth/magic-link`. Without it, sign-in returns a 500.

`railway.json` pins the Dockerfile builder, the `node dist/index.js` start command, and a `/health` healthcheck. Railway gives the service a public `*.up.railway.app` HTTPS domain (used later for the Strava webhook).

The Dockerfile is multi-stage: deps → build (Prisma generate + `tsc`) → minimal runtime image as non-root.
