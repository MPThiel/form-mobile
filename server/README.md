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

## Deploy (Fly.io)

```sh
fly launch --no-deploy        # if app doesn't exist yet
fly secrets set DATABASE_URL=... SUPABASE_PROJECT_URL=... ANTHROPIC_API_KEY=... ...
fly deploy
```

The Dockerfile is multi-stage: deps → build (Prisma generate + `tsc`) → minimal runtime image as non-root.
