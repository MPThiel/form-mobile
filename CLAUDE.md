# FORM Mobile — Claude Project Instructions

---

## What This Project Is

FORM Mobile is a Flutter app for iOS and Android — a ground-up rebuild of the v1 HTML prototype. It pairs an adaptive AI coach with daily activity logging (manual, photo-based meals, Strava sync, Apple Health / Google Fit), and ships to the App Store and Google Play Store.

The full architecture and rebuild plan are in `FORM-mobile-build-spec.md`. Read it before making any structural change. Do not deviate without flagging the change first.

The repo is split into two top-level packages:
- `app/` — Flutter mobile client
- `server/` — Node.js + Fastify + Prisma backend

---

## Project Files

| File | Purpose |
|---|---|
| `FORM-mobile-build-spec.md` | Master architecture document. Source of truth. |
| `CLAUDE.md` | This file. Read at the start of every session. |
| `app/` | Flutter app source |
| `server/` | Backend API source |
| `prisma/schema.prisma` | Database schema |

---

## Tech Stack — Non-Negotiable

### Mobile
- **Flutter** stable, **Dart 3.x**
- **Riverpod** for state (not Provider, not Bloc)
- **go_router** for navigation
- **dio** for HTTP with a JWT auth interceptor
- **drift** for local SQLite cache
- **flutter_secure_storage** for JWT
- **health** package for HealthKit + Health Connect
- **fl_chart** for charts
- **google_fonts** for Montserrat + Space Grotesk

### Backend
- **Node.js 20+, Fastify, TypeScript**
- **Prisma** ORM, **PostgreSQL** 15+
- **Supabase Auth** for JWT issuance (verified via JWKS, not Supabase SDK)
- **Cloudflare R2** for meal photo storage

### What's banned
- No direct calls from the Flutter client to the Anthropic API, Strava API, or any third-party service that requires secrets.
- No API keys in `pubspec.yaml`, `Info.plist`, `AndroidManifest.xml`, env files committed to git, or anywhere else in the client bundle.
- No `setState` outside of trivial widget-local UI state. Anything cross-screen uses Riverpod.
- No raw SQL in the app — use Drift. No raw SQL in the backend — use Prisma.
- No `localStorage`-equivalent for sensitive data. JWTs and tokens go through `flutter_secure_storage` only.

---

## Flutter App Structure

```
app/
├── lib/
│   ├── main.dart
│   ├── app.dart                    — MaterialApp + router + theme
│   ├── core/
│   │   ├── theme/                  — FormTheme, colour tokens, text styles
│   │   ├── router/                 — go_router config, route guards
│   │   ├── http/                   — Dio client, auth interceptor
│   │   └── storage/                — Secure storage, Drift database
│   ├── features/
│   │   ├── auth/                   — Sign-in screens, providers, repository
│   │   ├── onboarding/             — 6-screen wizard
│   │   ├── home/                   — Dashboard tab
│   │   ├── coach/                  — Chat tab, streaming consumer
│   │   ├── camera/                 — Meal photo flow, confirmation sheet
│   │   ├── profile/                — Profile + integrations + progress
│   │   ├── plan/                   — Weekly plan generation + approval
│   │   └── log/                    — Manual logging widgets (used across tabs)
│   └── shared/
│       ├── widgets/                — Reusable components (StatCard, etc.)
│       └── models/                 — Freezed data classes shared across features
└── pubspec.yaml
```

Each feature folder follows this structure:
```
feature_name/
├── data/         — repositories, API clients, Drift DAOs
├── domain/       — Freezed models, enums
├── presentation/ — screens, widgets specific to this feature
└── providers.dart — Riverpod providers exposed by this feature
```

---

## Theme

All colours and typography come from `FormTheme` in `core/theme/`. Never hardcode hex values or font sizes in widgets — always reference theme tokens.

```dart
class FormColors {
  static const bg = Color(0xFF131313);
  static const surface = Color(0xFF1C1B1B);
  static const surfaceHigh = Color(0xFF2A2A2A);
  static const border = Color(0xFF353534);
  static const primary = Color(0xFFFF6B00);     // electric orange
  static const secondary = Color(0xFF00EEFC);   // cyber cyan
  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFE2BFB0);
  static const success = Color(0xFF52E89A);
  static const warning = Color(0xFFFFD166);
  static const danger = Color(0xFFF87171);
}
```

Macro colour coding — consistent across the app, matching v1:
- Calories → `primary` (orange)
- Protein → `secondary` (cyan)
- Carbs → `warning` (yellow)
- Fat → `success` (green)

Typography: Montserrat for prose, Space Grotesk for numeric and label text. Sizes match `DESIGN.md`.

---

## State Management Patterns

- Every API-backed entity is exposed as an `AsyncNotifierProvider` (Riverpod 2.x style).
- Mutations are methods on the notifier, never standalone functions.
- UI consumes state via `ref.watch(...)` and reacts to `AsyncValue` (`loading`, `error`, `data`).
- Server-side errors bubble up as `AsyncValue.error` with a typed `FormException`, never a raw `DioException`.

Example shape:
```dart
@riverpod
class TodayLog extends _$TodayLog {
  @override
  Future<DailyLog> build() async {
    return ref.read(logRepositoryProvider).fetchToday();
  }

  Future<void> logMeal(Meal meal) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(logRepositoryProvider).addMeal(meal);
      return ref.read(logRepositoryProvider).fetchToday();
    });
  }
}
```

---

## Backend Structure

```
server/
├── src/
│   ├── index.ts                — Fastify bootstrap
│   ├── plugins/
│   │   ├── auth.ts             — JWT verification via Supabase JWKS
│   │   ├── prisma.ts           — Prisma client decorator
│   │   └── errorHandler.ts
│   ├── routes/
│   │   ├── auth.ts
│   │   ├── profile.ts
│   │   ├── logs.ts
│   │   ├── meals.ts            — incl. POST /meals/analyze
│   │   ├── coach.ts            — incl. streaming chat
│   │   ├── plan.ts
│   │   ├── strava.ts           — OAuth + webhook
│   │   └── health.ts           — server health check
│   ├── services/
│   │   ├── claude.ts           — Anthropic API wrapper
│   │   ├── strava.ts           — Strava API wrapper + token refresh
│   │   ├── r2.ts               — Cloudflare R2 upload
│   │   └── coachPrompt.ts      — system prompt builder
│   └── lib/
│       └── crypto.ts           — token encryption helpers
├── prisma/
│   └── schema.prisma
└── package.json
```

### Environment Variables (server-side only, never client)
```
DATABASE_URL=
SUPABASE_PROJECT_URL=
SUPABASE_JWT_SECRET=
ANTHROPIC_API_KEY=
STRAVA_CLIENT_ID=
STRAVA_CLIENT_SECRET=
STRAVA_WEBHOOK_VERIFY_TOKEN=
STRAVA_TOKEN_ENCRYPTION_KEY=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET=
R2_ENDPOINT=
```

Never log any of these. Never commit them. Use `.env.example` with empty values for documentation.

---

## API Contracts

All endpoints return JSON. All require `Authorization: Bearer <jwt>` except `/health` and `/strava/webhook`.

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/profile` | Profile fields | Profile |
| GET | `/logs/today` | — | DailyLog |
| GET | `/logs/range?from=&to=` | — | DailyLog[] |
| POST | `/logs/meals` | Meal | Meal |
| POST | `/logs/runs` | Run | Run |
| POST | `/logs/workouts` | Workout | Workout |
| POST | `/logs/weight` | { weight } | DailyLog |
| POST | `/meals/analyze` | multipart photo | Meal (unsaved, pending user confirmation) |
| POST | `/coach/message` | { message } | SSE stream of tokens, then full ChatMessage |
| POST | `/coach/briefing` | — | { text } |
| POST | `/plan/generate` | — | WeekPlan (pending approval) |
| POST | `/plan/approve` | { weekStart } | WeekPlan |
| POST | `/strava/connect` | { code } | StravaConnection |
| DELETE | `/strava/connect` | — | 204 |
| POST | `/strava/webhook` | Strava payload | { received: true } |

---

## Claude API Rules

- Model: always `claude-sonnet-4-20250514`. Never change without explicit instruction.
- All calls go through `services/claude.ts`. Never inline a `fetch` to Anthropic anywhere else.
- System prompts are built fresh on every call by `services/coachPrompt.ts` from the current user state — never cached.
- Token budgets per call type are documented in the build spec (section 8). Respect them.
- Chat responses stream via SSE. Other call types return whole responses.
- Every call wrapped in try/catch. On failure, return a structured error the client can show as a toast.

---

## Build Phases

Follow the order in `FORM-mobile-build-spec.md` section 13. Each phase ships a working build to TestFlight + Play Internal Testing before the next phase begins. Do not let phases overlap.

---

## Coding Conventions

- Dart: format with `dart format`, lints from `package:flutter_lints`. No analyser warnings allowed in committed code.
- TypeScript: `strict: true`, no `any`, lint with ESLint + `@typescript-eslint/strict`.
- Commit messages: conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`).
- Branch per phase: `phase/01-auth`, `phase/02-onboarding`, etc.
- Every backend endpoint has at least one integration test (Vitest + supertest equivalent).
- Every Flutter screen has a widget test for its empty state, loading state, and a happy-path render.

---

## What NOT to Build in v1

- Apple Watch / Wear OS companion
- Push notifications
- Social / friends / leaderboards
- Manual food database, barcode scanning
- Detailed exercise library, guided workouts
- Multi-language support
- Tablet-optimised layouts

Flag any request to add these as out-of-scope for v1.

---

## Key Decisions Already Made

These are closed. Do not reopen without explicit instruction from Mark.

- Flutter, not React Native or native
- Own Node/Fastify backend, Supabase migration later
- Supabase Auth from day one
- Sign in with Apple + Google + Email magic link
- Adaptive coach (strict/balanced/gentle), no named persona
- Four tabs: Home / Coach / Camera / Profile
- Photo meal logging with editable confirmation sheet
- Strava via OAuth + webhook
- Apple Health + Google Fit via the `health` package
- Free during beta, RevenueCat-ready for paid later
- Dark theme only

---

*Last updated: May 2026. Refer to FORM-mobile-build-spec.md for full technical detail.*
