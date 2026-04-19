# Gym Membership SaaS — repo guide for Claude Code

## What this repository is

Anonymized public portfolio fork of a real freelance engagement (single-site
gym management: members, subscriptions, QR check-in, groups, staff
dashboard, automated emails). The real project is **out of scope for this
repo**; the brand is *FitClub*, member names and amounts are synthetic,
and the original production Supabase project has been closed.

- **GitHub**: https://github.com/Teina-max/gym-membership-saas (public, MIT)
- **Live demo**: _none — original Supabase project was closed after delivery_
- **Narrative**: see [`CASE_STUDY.md`](./CASE_STUDY.md)
- **User-facing pitch**: see [`README.md`](./README.md)

## Hard constraints

1. **NEVER revert the anonymization**. If you find any string that looks
   like a real client identifier (the original gym was based in a French
   Pacific territory, used XPF currency, and had specific staff names),
   treat it as a bug and scrub it. Search patterns to flag:
   - `UFC`, `Wallis`, `Futuna`, `UVEA`, `XPF`, `Pacific/Wallis`
   - `Kava Fotofili`, `Soane Tui`, `Malia Liku`, `Petelo Vaimu'a`
   - Any `@mail.wf`, `@ufc-gym.wf`, or `+681` phone number
2. **NEVER commit secrets**. `.env`, `.env.local`, and any file matching
   `.env*.local` are gitignored. The original Supabase URL + anon key
   were removed before first commit and are not to be restored.
3. **NEVER commit the original internal documents**. `ABOUT.md`,
   `SPRINTS.md`, `commerciale/`, and `sprints/` were removed before
   first commit (they contained contract amounts, pricing, and internal
   planning). If you find yourself recreating any of them from memory,
   stop.

## Status snapshot

| Area | Status |
|---|---|
| Anonymization | Complete |
| Git history | Clean, 0 secrets |
| GitHub publish | Public · MIT |
| Supabase demo DB | None — original project closed |
| Live deploy | None |

## How to work here

### Conventions
- TypeScript strict, ESM, `camelCase` / `PascalCase`.
- Commits: short, descriptive, **English**.
- UI: French. Code, commits and identifiers: English.
- No over-engineering; no silent fallbacks; fail fast.
- Comments explain *why*, not *what*. Default is no comment.

### Stack
- Runtime: Bun
- Frontend: React 19 + Vite + TypeScript + TanStack Router + shadcn/ui + Tailwind v4
- Backend: Supabase (PostgreSQL, Auth, RLS, Edge Functions, Realtime, Storage)
- Auth: Supabase Auth (email/password) + CASL (frontend RBAC)
- Forms: react-hook-form + Zod
- Data fetching: TanStack Query
- QR: `react-qr-code` (generation) + `qr-scanner` (scanning)
- PDF: jsPDF (client-side receipts)
- Email: Resend (via Supabase Edge Function)
- Charts: Recharts via shadcn/ui Charts
- Testing: Vitest + React Testing Library + Playwright (E2E)

### Commands

```bash
bun dev              # start dev server
bun build            # production build
bun lint             # ESLint
bun typecheck        # TypeScript check
bun test:run         # run tests (never use `bun test` — watch mode)
supabase start       # start local Supabase stack
supabase db reset    # reset local DB + apply migrations + seed
```

### Architecture

```
src/
├── lib/
│   ├── supabase/      # singleton client + generated types
│   ├── casl/          # defineAbilityFor(role) + <Can> component
│   └── utils/         # currency, date, QR helpers
├── features/          # vertical slices (3-layer: api/ · services/ · hooks/ · components/)
├── components/ui/     # shadcn/ui primitives
└── routes/            # TanStack Router file-based routes
    ├── _admin/        # staff layout + role guard
    └── _member/       # member layout + role guard

supabase/
├── migrations/        # 15 SQL migrations
├── seed.sql           # synthetic test data
└── functions/         # Edge Functions (email, QR token)
```

### Key patterns

- **3-layer per feature**: `api/` (Supabase queries) → `services/` (pure business logic) → `hooks/` (TanStack Query wrappers) → `components/` (presentation).
- **Double protection**: RLS server-side (source of truth) + CASL frontend (UX masking).
- **RLS on every table, no exceptions.** Roles stored in `profiles.role`, injected into JWT via Auth Hook.
- **Integer amounts only.** All prices / payments are `int` — no decimals. The default currency is EUR but the formatter (`src/lib/utils/currency.ts`) and timezone (`src/lib/utils/date.ts`) are meant to be swapped per deployment.
- **Soft delete.** Sensitive tables use `deleted_at` instead of hard DELETE.
- **QR codes are HMAC-signed and short-lived** (validated server-side in `validate_qr_token`).

## Glossary

| Term | Value |
|---|---|
| GitHub repo | `Teina-max/gym-membership-saas` |
| Fictional brand | FitClub |
| Fictional personae | Alice Martin (admin) · Bruno Dubois (manager) · Claire Bernard (front desk) · David Leroy (coach) |
| Default currency | EUR (integer, no decimals) — swap in `currency.ts` |
| Default timezone | Europe/Paris — swap in `date.ts` |
