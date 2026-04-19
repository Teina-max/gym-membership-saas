# 🏋️ Gym Membership SaaS

> **From paper notebook to real-time operations in 3 weeks.**
> A custom-built gym management system — members, subscriptions, QR
> check-in, groups, staff dashboard, automated emails — shipped for a
> real single-site gym, open-sourced here as an anonymized portfolio
> fork (fictional brand *FitClub*, 100 % synthetic data).

<p>
  <a href="https://react.dev"><img alt="React 19" src="https://img.shields.io/badge/React-19-61dafb?logo=react&logoColor=000"></a>
  <a href="https://vite.dev"><img alt="Vite" src="https://img.shields.io/badge/Vite-8-646cff?logo=vite&logoColor=fff"></a>
  <a href="https://supabase.com"><img alt="Supabase" src="https://img.shields.io/badge/Supabase-Postgres%20%2B%20RLS-3ecf8e?logo=supabase&logoColor=fff"></a>
  <a href="https://tanstack.com/router"><img alt="TanStack Router" src="https://img.shields.io/badge/TanStack-Router-ff4154?logo=reactquery&logoColor=fff"></a>
  <a href="https://casl.js.org"><img alt="CASL" src="https://img.shields.io/badge/RBAC-CASL-7c3aed"></a>
  <a href="https://ui.shadcn.com"><img alt="shadcn/ui" src="https://img.shields.io/badge/UI-shadcn%2Fui-000"></a>
  <a href="https://bun.sh"><img alt="Bun" src="https://img.shields.io/badge/Runtime-Bun-f9f1e1?logo=bun&logoColor=000"></a>
</p>

---

## 🧭 TL;DR

| | |
|---|---|
| **Business problem** | Single-site gym running on notebooks + Excel. No off-the-shelf SaaS fit (French UI, configurable locale, budget). Zero visibility on revenue, churn, attendance. Check-in was manual and slow. |
| **What I built** | Member CRUD with photo + QR code + emergency contact · 6 subscription plans with automatic expiry + reminders · HMAC-signed QR check-in (< 5 s target) · Institutional groups (clubs, schools) with fixed monthly billing · Real-time staff dashboard · RBAC with 5 roles · Transactional emails (Resend). |
| **Timeline** | 3 weeks, solo dev, from empty repo to delivery. |
| **Stack** | React 19 · Vite · TypeScript · TanStack Router · shadcn/ui + Tailwind v4 · Supabase (Postgres + RLS + Edge Functions + Realtime + Storage) · CASL · Resend · Vercel. |
| **Code size** | 15 SQL migrations · 11 Postgres functions · 4 Edge Functions · 9 vertical-slice features · Vitest + Playwright test setup. |

👉 Full narrative, trade-offs and lessons learned in **[`CASE_STUDY.md`](./CASE_STUDY.md)**.

---

## 🏗 Architecture

```
                   ┌───────────────────────────────────────┐
                   │    React 19 + Vite SPA (admin SPA)    │
                   │  Login · Members · Check-in · Groups  │
                   │  Dashboard · Staff · Audit            │
                   │  RLS-aware Supabase client + CASL     │
                   └────────────┬─────────────┬────────────┘
                                │             │
                    QR payload  │             │  REST / RPC
                    (HMAC)      ▼             ▼
                        ┌──────────────┐  ┌─────────────────┐
                        │ validate_qr_ │  │    Supabase     │
                        │   token()    │  │    Postgres     │
                        │ Postgres fn  │  │  11 functions   │
                        └──────┬───────┘  │  15 migrations  │
                               │          │  RLS everywhere │
                               └────────▶ └────┬────────────┘
                                               │
                                               │ pg_cron
                                               ▼
                                        ┌─────────────────┐
                                        │  Edge Function  │
                                        │  send-reminder  │────┐
                                        │  (J-3, J-0)     │    │
                                        └─────────────────┘    │
                                                               ▼
                                                         ┌──────────┐
                                                         │  Resend  │
                                                         └──────────┘
```

### Key decisions

- **No custom backend.** The React client talks to Supabase directly. Business logic lives in Postgres functions; side-effects (email, QR token generation) in Edge Functions. Fewer moving parts, less infra to maintain.
- **RLS is the security boundary.** Every table, every role, every operation — explicit policies. CASL on the frontend is pure UX.
- **3-layer feature slices.** `api/` (Supabase queries) → `services/` (pure business logic) → `hooks/` (TanStack Query wrappers) → `components/`. Services are framework-agnostic and trivially unit-testable.
- **Signed QR codes.** Short-lived HMAC tokens, validated server-side. A static member ID in a QR can be screenshotted and reused; this can't.
- **Soft deletes only** on sensitive entities (`deleted_at`). DELETE via API is disabled at the RLS layer.
- **Integer amounts.** Prices and payments are `int`. Currency + timezone are pluggable in two files (`currency.ts`, `date.ts`) — defaults ship as EUR / Europe/Paris.

---

## 📦 Repo layout

```
├── app config (vite, tsconfig, eslint)
├── src/
│   ├── lib/{supabase, casl, utils}
│   ├── features/                  # 9 vertical slices
│   ├── components/ui/             # shadcn primitives
│   └── routes/{_admin, _member}   # TanStack Router
├── supabase/
│   ├── migrations/                # 15 SQL files
│   ├── functions/                 # 4 Edge Functions
│   └── seed.sql                   # synthetic test data
├── docs/
│   ├── PRD.md                     # product requirements
│   └── ARCHI.md                   # architecture deep-dive
└── design/
    └── design-tokens.md           # color / type / spacing tokens
```

---

## 🚀 Running locally

```bash
# 1. install
bun install

# 2. boot local Supabase (Postgres, Auth, Studio)
supabase start

# 3. apply migrations + seed
supabase db reset

# 4. env
cp .env.example .env.local
# fill VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY from `supabase status`

# 5. dev server
bun dev
```

Local Studio: http://localhost:54323
App: http://localhost:5173

Test accounts (password `password123` for all):
- `admin@fitclub.test` — full access
- `manager@fitclub.test` — admin minus destructive ops
- `accueil@fitclub.test` — front desk
- `coach@fitclub.test` — coach scope
- `emma.durand@mail.test` — member

---

## 🔐 Status

| Area | State |
|---|---|
| Anonymization | Complete |
| Git history | Clean, 0 secrets |
| GitHub publish | Public · MIT |
| Live demo | None — original Supabase project was closed after delivery |

---

## 📄 License

MIT — see [`LICENSE`](./LICENSE).
