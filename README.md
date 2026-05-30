# FORM Mobile

A fitness companion for iOS and Android — adaptive AI coach, photo-based meal logging, Strava + Apple Health / Google Fit sync.

## Repo layout

```
form-mobile/
├── app/                       Flutter mobile client (iOS + Android)
├── server/                    Node + Fastify + Prisma backend
├── .github/workflows/         CI for both packages
├── CLAUDE.md                  Working instructions (read at start of every session)
└── FORM-mobile-build-spec.md  Master architecture document — source of truth
```

For the project overview, tech stack rules, folder conventions, API contracts, and build phases, read [CLAUDE.md](CLAUDE.md) and [FORM-mobile-build-spec.md](FORM-mobile-build-spec.md). Everything that matters is in those two files.

## Running locally

### Backend

```sh
cd server
cp .env.example .env          # fill in real values
npm install
npm run prisma:generate
npm run prisma:migrate        # requires DATABASE_URL pointing at a local Postgres
npm run dev                   # http://localhost:3000
```

`GET /health` returns `{ "status": "ok" }`.

### Flutter app

```sh
cd app
flutter pub get
flutter run                   # picks the connected device / simulator
```

## Deploy

The backend deploys to **Railway** (Git-push deploys, automatic Postgres provisioning, free `*.up.railway.app` HTTPS domain). The Railway service's **Root Directory** is set to `server`, so it picks up [server/railway.json](server/railway.json) and the multi-stage [server/Dockerfile](server/Dockerfile). See [server/README.md](server/README.md#deploy-railway) for the deploy steps and required secrets.

## CI

- [.github/workflows/app.yml](.github/workflows/app.yml) — `flutter analyze`, `flutter test`, iOS build (no signing), Android APK build.
- [.github/workflows/server.yml](.github/workflows/server.yml) — lint, typecheck, `prisma validate`, vitest.

## Status

Phase 0 (skeleton). See section 13 of [FORM-mobile-build-spec.md](FORM-mobile-build-spec.md) for the build phase plan.
