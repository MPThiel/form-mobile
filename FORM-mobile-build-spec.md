# FORM Mobile — Build Specification

A ground-up rebuild of FORM as a cross-platform mobile app for the iOS App Store and Google Play Store. Keeps the core feature set of the v1 HTML prototype (adaptive AI coach, photo-based meal logging, weekly plan, progress tracking), adds Strava + Apple Health + Google Fit sync, and is built on a stack that supports a paid public product.

---

## 1. What's Changing from v1

| Area | v1 (HTML) | v2 (Mobile) |
|---|---|---|
| Platform | Single-file HTML, personal use | Flutter app, iOS + Android, public |
| Storage | `window.storage` artifact API | Server-authoritative + local cache |
| AI calls | Direct from browser | Proxied through own backend |
| Auth | None | Apple + Google + email |
| Activity data | Manual log only | Strava + Health/Fit + manual |
| Distribution | Open the HTML file | App Store + Play Store |
| Monetization | None | Free during beta, paid post-launch |

The product idea, data model, and coaching behaviour stay the same. The architecture changes completely.

---

## 2. Tech Stack — Non-Negotiable

### Mobile (Flutter)
- **Flutter** stable channel, Dart 3.x
- **Riverpod** for state management (preferred over Provider/Bloc for solo dev velocity)
- **go_router** for navigation
- **dio** for HTTP, with auth interceptor
- **drift** for local SQLite cache (offline-first reads)
- **flutter_secure_storage** for auth tokens
- **image_picker** + **camera** for meal photos
- **health** package for HealthKit (iOS) + Health Connect (Android)
- **fl_chart** for progress charts (Chart.js equivalent)
- **google_fonts** for Montserrat + Space Grotesk

### Backend (own, migrating to Supabase later)
- **Node.js + Fastify + TypeScript** (recommended — translates cleanly to Supabase Edge Functions later)
- **Prisma** + **PostgreSQL** (Prisma schema mirrors directly into Supabase)
- **Supabase Auth** from day one, even on own backend — it works standalone via JWT verification and is the one piece that needs zero rework at migration
- Hosted on **Railway** (same account already in use for Scholar's Quest, $5/mo Hobby plan with $5 of included credits, Git-push deploys, automatic Postgres provisioning)

If you'd rather use Python: FastAPI + SQLAlchemy is equivalent. Flag preference before phase 1 starts.

### Third-Party APIs
- **Anthropic Claude API** — `claude-sonnet-4-20250514`, called only from backend
- **Strava API v3** — OAuth2 + webhook subscriptions
- **Apple HealthKit** — via `health` package, requires entitlements
- **Google Health Connect** — via `health` package, requires manifest permissions

---

## 3. Architecture

```
┌─────────────────────┐         ┌──────────────────────┐
│   Flutter App       │◄───────►│   Own Backend        │
│   (iOS / Android)   │  HTTPS  │   (Fastify + PG)     │
│                     │   JWT   │                      │
│  - Riverpod state   │         │  - Auth (Supabase)   │
│  - Drift cache      │         │  - Strava OAuth      │
│  - HealthKit/HC     │         │  - Claude proxy      │
└─────────────────────┘         │  - Webhook receiver  │
                                └──────┬───────────────┘
                                       │
                          ┌────────────┼────────────┐
                          ▼            ▼            ▼
                    ┌─────────┐  ┌──────────┐  ┌─────────┐
                    │ Anthr.  │  │  Strava  │  │ Postgres│
                    │  API    │  │   API    │  │         │
                    └─────────┘  └──────────┘  └─────────┘
```

### Why all AI calls go through the backend
- API keys MUST NOT ship in the mobile binary. App Store reviewers will reject; the keys would be trivially extractable from the IPA/APK.
- The backend also enforces per-user rate limits and abuse protection, which become critical when monetization arrives.
- The backend is where Strava webhook events land — so it's already the system of record.

---

## 4. Data Model (Server-Authoritative)

Postgres schema mirrors the v1 domain but normalised. Prisma schema sketch:

```prisma
model User {
  id                String     @id @default(cuid())
  email             String     @unique
  authProvider      String     // "apple" | "google" | "email"
  createdAt         DateTime   @default(now())
  profile           Profile?
  logs              DailyLog[]
  stravaConnection  StravaConnection?
  weekPlans         WeekPlan[]
  chatMessages      ChatMessage[]
}

model Profile {
  userId             String   @id
  user               User     @relation(fields: [userId], references: [id])
  currentWeight      Float
  targetWeight       Float
  age                Int
  trainingHistory    String   // enum-as-string
  goals              Json     // [{ id, rank }]
  mood               Int      // 1-5
  energy             Int      // 1-5
  physicalNotes      String?
  nutritionStyle     String
  dailyCalorieTarget Int
  weeklyRunKmTarget  Float
  weeklyWorkoutDays  Int
  setupDate          DateTime
}

model DailyLog {
  id        String     @id @default(cuid())
  userId    String
  user      User       @relation(fields: [userId], references: [id])
  date      DateTime   @db.Date
  weight    Float?
  meals     Meal[]
  runs      Run[]
  workouts  Workout[]
  @@unique([userId, date])
}

model Meal {
  id         String   @id @default(cuid())
  dailyLogId String
  log        DailyLog @relation(fields: [dailyLogId], references: [id])
  name       String
  calories   Int
  protein    Int
  carbs      Int
  fat        Int
  photoUrl   String?  // S3/R2 url
  timestamp  DateTime
}

model Run {
  id          String   @id @default(cuid())
  dailyLogId  String
  log         DailyLog @relation(fields: [dailyLogId], references: [id])
  distanceKm  Float
  durationSec Int
  paceSecPerKm Int
  source      String   // "manual" | "strava" | "healthkit" | "healthconnect"
  externalId  String?  // strava activity id, etc.
  timestamp   DateTime
  @@unique([source, externalId])
}

model Workout {
  id          String   @id @default(cuid())
  dailyLogId  String
  log         DailyLog @relation(fields: [dailyLogId], references: [id])
  type        String
  durationMin Int
  difficulty  Int      // 1-10
  notes       String?
  source      String
  externalId  String?
  timestamp   DateTime
  @@unique([source, externalId])
}

model StravaConnection {
  userId        String   @id
  user          User     @relation(fields: [userId], references: [id])
  athleteId     BigInt   @unique
  accessToken   String   // encrypted at rest
  refreshToken  String   // encrypted at rest
  expiresAt     DateTime
  connectedAt   DateTime @default(now())
}

model WeekPlan {
  id          String   @id @default(cuid())
  userId      String
  user        User     @relation(fields: [userId], references: [id])
  weekStart   DateTime @db.Date
  approved    Boolean  @default(false)
  proposedAt  DateTime @default(now())
  days        Json     // { "YYYY-MM-DD": { type, label, targetKm?, targetMin? } }
  @@unique([userId, weekStart])
}

model ChatMessage {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id])
  role      String   // "user" | "assistant"
  content   String
  createdAt DateTime @default(now())
  @@index([userId, createdAt])
}
```

Key changes from v1:
- Streak is now derived from `DailyLog` rows rather than stored — simpler, no drift.
- `(source, externalId)` unique constraint on Run/Workout prevents duplicate Strava imports.
- Strava tokens are encrypted at rest using a per-app key (env var `STRAVA_TOKEN_ENCRYPTION_KEY`).

---

## 5. Authentication

### Recommendation: Sign in with Apple + Google + Email magic link
- **Apple's rule:** if you offer any third-party social sign-in, you must offer Sign in with Apple. Skipping it = rejection.
- **Email magic link** (no password) is lower friction than email+password and avoids storing password hashes.
- Use **Supabase Auth** as the provider from day one. It handles Apple/Google/email magic link out of the box, issues JWTs your own backend can verify with the public JWKS endpoint. When you migrate, nothing changes for users.

### Flow
1. User taps "Sign in with Apple/Google/Email" in Flutter.
2. Supabase Auth handles the provider dance and returns a JWT.
3. Flutter stores JWT in `flutter_secure_storage` (Keychain / Keystore).
4. Every backend call attaches `Authorization: Bearer <jwt>`.
5. Backend middleware verifies the JWT against Supabase JWKS, extracts `user.id`, attaches to request.

---

## 6. Strava Integration

### Prerequisite (BEFORE any code)
Register an app at https://developers.strava.com/ to get `client_id` and `client_secret`. Required fields:
- Application name: FORM
- Category: Training
- Website: your landing page (or a placeholder you control)
- Authorization Callback Domain: your backend domain
- Default access: `activity:read_all`

Strava allows 1,000 daily auth requests for unverified apps — fine for beta. Apply for higher limits before public launch.

### OAuth Flow
1. Flutter opens `https://www.strava.com/oauth/mobile/authorize?...&redirect_uri=form://strava/callback` in an in-app browser (`flutter_web_auth_2`).
2. User approves, Strava redirects to the deep link `form://strava/callback?code=...`.
3. Flutter sends the code to backend `POST /strava/connect { code }`.
4. Backend exchanges code for tokens at Strava's `/oauth/token` endpoint.
5. Backend encrypts and stores `access_token`, `refresh_token`, `expires_at` in `StravaConnection`.
6. Backend immediately fetches the last 30 days of activities and inserts as `Run` / `Workout` records.

### Activity Sync (push, not poll)
- Subscribe to Strava's **webhook events** at `POST /strava/webhook` on your backend (requires public HTTPS — Railway gives this for free with a `*.up.railway.app` domain).
- On every webhook (`object_type: activity, aspect_type: create|update|delete`), fetch the activity and upsert into the matching `Run` or `Workout` row using `(source, externalId)`.
- Polling fallback runs every 6 hours via a cron job, in case webhooks are missed.

### Token Refresh
Strava access tokens expire after 6 hours. Backend checks `expiresAt` before any call; if within 10 minutes of expiry, refresh and update the row.

---

## 7. Health Integration (HealthKit + Health Connect)

Use the **`health`** Flutter package — it abstracts both platforms behind one API.

### iOS (HealthKit)
- Enable HealthKit capability in Xcode.
- `Info.plist` keys required: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` — both must explain *why* in plain language ("FORM reads your steps and weight to calculate daily progress").
- Read permissions: `STEPS`, `WEIGHT`, `ACTIVE_ENERGY_BURNED`, `HEART_RATE`.
- Write permissions: `WEIGHT` only (so logged weights sync back to Health).

### Android (Health Connect)
- `AndroidManifest.xml` requires `<uses-permission>` entries for each data type.
- Health Connect is a separate app — handle the case where it's not installed (deep-link to Play Store).
- Same data types as iOS.

### Sync Behaviour
- On app foreground, read the last 24 hours of steps + any new weight entries.
- Steps are displayed on the Home tab but **not stored** in our DB (they're cheap to re-read).
- Weight entries are upserted into `DailyLog.weight` if not already present from manual logging.

---

## 8. Claude API Proxy

Backend endpoint: `POST /coach/message`

Request body from Flutter:
```json
{ "message": "Should I run today?" }
```

Backend flow:
1. Verify JWT, look up user.
2. Load profile, today's `DailyLog`, current `WeekPlan`, last 20 `ChatMessage` rows.
3. Build the adaptive system prompt (port the template from v1 spec section 12).
4. Call `https://api.anthropic.com/v1/messages` with the model and messages.
5. Stream the response back to Flutter using **Server-Sent Events** (`text/event-stream`).
6. Persist both user message and assistant response to `ChatMessage`.

Same pattern for the other call types from v1:
| Endpoint | Purpose | Max tokens |
|---|---|---|
| `POST /coach/message` | Chat reply | 500 |
| `POST /coach/briefing` | Morning briefing | 200 |
| `POST /coach/welcome` | Post-onboarding welcome | 250 |
| `POST /meals/analyze` | Vision meal analysis | 300 |
| `POST /plan/generate` | Weekly plan generation | 800 |
| `POST /plan/adjust` | Plan tweak from chat | 400 |

---

## 9. Photo Meal Logging

1. Flutter opens camera via `camera` package (or `image_picker` for gallery).
2. Image compressed to ≤1MB JPEG client-side (`flutter_image_compress`).
3. POST as `multipart/form-data` to `/meals/analyze`.
4. Backend uploads image to **Cloudflare R2** (cheaper than S3, no egress fees), stores the URL.
5. Backend sends base64 image to Claude Vision with the meal-analysis prompt from v1.
6. Claude returns JSON `{ name, calories, protein, carbs, fat, confidence }`.
7. Backend inserts `Meal` row with `photoUrl`, returns the row to Flutter.
8. Flutter shows the analysis in a confirmation sheet — user can edit any field before saving.

The edit step is new vs v1. Vision is good but not perfect; the confirmation sheet prevents bad data and is also a graceful failure mode when confidence is low.

---

## 10. Offline Behaviour

The Drift local cache is the source of truth for reads when offline:
- Last 30 days of `DailyLog`, current `WeekPlan`, last 50 `ChatMessage` rows are cached.
- Writes (logging a meal, weight, etc.) go to a local outbox table when offline, drain to backend on reconnect.
- Photo meal analysis is **online-only** — show a clear "needs connection" state.
- Coach chat is online-only — show typing indicator with timeout, fall back to "Coach unavailable" toast.

---

## 11. Design System Mapping

The v2 `DESIGN.md` tokens translate directly to a Flutter `ThemeData`. The mockup screens (Alex Mercer / Coach Sandow / PRO badge) are reference for visual *style only* — strip the personas and brand-name copy. Keep:
- True dark palette (#131313 base)
- Electric orange (#FF6B00) as primary accent
- Cyber cyan (#00EEFC) for AI/data elements
- Montserrat for prose, Space Grotesk for numeric data and labels
- Card-based layout with 1px borders, no heavy shadows
- Glow effects on primary buttons and active states
- 16px corner radius on cards/buttons, 8px on chips/inputs

The four-tab structure stays: **Home / Coach / Camera / Profile**. Note this is one tab different from the v1 spec (which had Home / Log / Coach / Progress) — the mockups consolidate Log into Camera + Profile and absorb Progress into Profile. This is the better mobile arrangement and should be the v2 structure.

Bottom nav minimum tap target: 48×48 logical pixels on both platforms.

---

## 12. Subscription (Future, Plan For It Now)

Even though v1 launches free, the schema and architecture should be subscription-ready so the migration is a UI change, not a backend rewrite.

- Add `subscriptionTier` and `subscriptionExpiresAt` to `User` now, defaulted to `"free"`.
- Backend middleware can gate paid endpoints based on tier even when nothing is gated yet.
- Use **RevenueCat** when ready — it handles both App Store and Play Store IAP, webhook to your backend, receipt validation. Don't roll your own.
- Pricing decision deferred until beta feedback.

---

## 13. Build Phases

No fixed timeline. Each phase ships a working app build to TestFlight + Play Internal Testing before the next starts.

| Phase | Scope | Definition of done |
|---|---|---|
| 0 | Prerequisites — accounts, Strava registration, backend repo skeleton, Flutter repo skeleton, CI to build both platforms | App icon + splash screen render on a real device |
| 1 | Auth — Sign in with Apple/Google/Email magic link, JWT plumbing, basic Profile creation | Can sign in, see empty Home screen, sign out |
| 2 | Onboarding wizard — port the 6 screens from v1, save Profile to backend | New user lands on Home with a populated Profile |
| 3 | Home + Log tabs — stat cards, manual meal/weight/run/workout logging, local cache | Can log everything manually, data persists across launches and reinstalls |
| 4 | Camera meal logging — backend Vision proxy, R2 upload, confirmation sheet | Photo a plate, get analysis, save to log |
| 5 | Coach tab — chat UI, backend streaming proxy, morning briefing, system prompt | Can have a full coaching conversation, briefing fires once per day |
| 6 | Weekly plan — generation, approval modal, edit-via-coach | Plan generates Monday, shows on Home, can be reworked via chat |
| 7 | Strava integration — OAuth, initial backfill, webhook subscription, deep link | Connect Strava in Profile, last 30 days appear, new activity appears within 1 min |
| 8 | HealthKit + Health Connect — steps on Home, weight sync | Steps show today's count, weights logged in Health appear in FORM |
| 9 | Progress tab — fl_chart visualizations, streak calendar | All four chart types from v1, plus streak grid |
| 10 | Polish — empty states, error handling, accessibility audit, performance pass | Lighthouse/Flutter DevTools score acceptable, no obvious bugs in beta feedback |
| 11 | Store submission — privacy policy, support URL, screenshots, App Privacy labels, content rating | Approved on both stores |

---

## 14. Pre-Launch Checklist

### Accounts (do these first, they take days)
- [ ] Apple Developer Program enrollment ($99/yr) — requires D-U-N-S number for org, ~48hr approval for individual
- [ ] Google Play Console account ($25 one-time)
- [ ] Strava API application
- [ ] Cloudflare R2 account
- [ ] Railway project (already have account — just add a new project for FORM)
- [ ] Supabase project (Auth-only initially)

### Legal / Required Documents
- [ ] Privacy Policy URL (covers: data collected, Strava data handling, Health data handling, Claude API usage, retention, deletion) — generate via Termly or write your own and host on your domain
- [ ] Terms of Service URL
- [ ] Support contact (email + a simple landing page section)
- [ ] App Privacy "nutrition labels" filled out in App Store Connect (food/health is a sensitive category — be precise)

### Store Assets
- [ ] App icon — 1024×1024 master, exported per platform
- [ ] Splash screen
- [ ] iOS screenshots — 6.7", 6.5", 5.5" iPhone sizes; iPad if supporting
- [ ] Android screenshots — phone + 7"/10" tablet if supporting
- [ ] App Store preview video (optional but boosts conversion)
- [ ] App description, keywords, category (Health & Fitness)

### Health Data Specific
- [ ] App Review note explaining Strava + Health usage (Apple reviewers will test this)
- [ ] HealthKit usage strings approved by you (these are visible to users in the permission prompt)
- [ ] Health Connect data type declarations in Play Console

---

## 15. Out of Scope for v1

- Apple Watch / Wear OS companion apps
- Push notifications (add post-launch based on demand)
- Social features, friends, leaderboards
- Manual food database / barcode scanning
- Detailed exercise library or guided workouts
- Multi-language support (English only at launch)
- Tablet-optimised layouts (works on tablet, not optimised)

Flag any request to add these as out of scope and propose a v1.x or v2 timeline instead.

---

## 16. Key Decisions Already Made

Closed. Do not reopen without explicit instruction.

- Flutter, not React Native or native
- Own Node/Fastify backend now, Supabase migration later
- Supabase Auth from day one (even on own backend)
- Adaptive coach (strict/balanced/gentle), no named persona
- Four tabs: Home / Coach / Camera / Profile
- Photo meal logging with editable confirmation sheet
- Strava via OAuth + webhook
- Apple Health + Google Fit via the `health` package
- Free during beta, RevenueCat-ready for subscription later
- Dark theme only

---

*This spec replaces FORM-build-spec.md for the mobile rebuild. The v1 HTML prototype remains as reference for product behaviour, prompt templates, and design intent only.*
