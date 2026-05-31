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

`GET /health` returns `{ "status": "ok" }`. The authenticated routes (`/me`)
need `SUPABASE_PROJECT_URL` set in `.env` so JWTs can be verified against the
project's JWKS, and `POST /auth/magic-link` (which sends the sign-in email)
needs `SUPABASE_SERVICE_ROLE_KEY` — see [server/.env.example](server/.env.example).

### Flutter app

Supabase credentials and the backend URL are passed at build time via
`--dart-define` (never hardcoded, never committed):

```sh
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000
```

- `SUPABASE_PUBLISHABLE_KEY` is the project's publishable (anon) key — safe to
  ship in the client. Found in Supabase → Project Settings → API.
- `BACKEND_BASE_URL` defaults to `http://10.0.2.2:3000`. On the **Android
  emulator**, `10.0.2.2` is the loopback alias that reaches the host machine's
  `localhost`, so it hits the backend from `npm run dev`. (iOS simulator can use
  `http://localhost:3000`; a physical device needs your machine's LAN IP.)

Launched without the two Supabase defines, the app shows a configuration screen
instead of crashing.

#### Magic-link sign-in setup

The magic-link email reopens the app via the custom scheme **`form://login-callback`**
(registered as an Android intent filter). Whitelist it in
Supabase → Authentication → URL Configuration → **Redirect URLs**:

```
form://login-callback
```

## Deploy

The backend deploys to **Railway** (Git-push deploys, automatic Postgres provisioning, free `*.up.railway.app` HTTPS domain). The Railway service's **Root Directory** is set to `server`, so it picks up [server/railway.json](server/railway.json) and the multi-stage [server/Dockerfile](server/Dockerfile). See [server/README.md](server/README.md#deploy-railway) for the deploy steps and required secrets.

Before deploying, add **`SUPABASE_SERVICE_ROLE_KEY`** to the Railway service variables (Supabase → Project Settings → API → `service_role` secret). The backend uses it to send magic-link emails via `POST /auth/magic-link`; sign-in fails without it.

## CI

- [.github/workflows/app.yml](.github/workflows/app.yml) — `flutter analyze`, `flutter test`, iOS build (no signing), Android APK build.
- [.github/workflows/server.yml](.github/workflows/server.yml) — lint, typecheck, `prisma validate`, vitest.

## Status

Phase 0 (skeleton). See section 13 of [FORM-mobile-build-spec.md](FORM-mobile-build-spec.md) for the build phase plan.
