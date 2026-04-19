# Case Study — Gym Membership SaaS

> Anonymized portfolio fork. The real engagement was a 3-week solo
> build for a single-site gym. Names, amounts, and locale have been
> genericized; every technical decision and trade-off below reflects
> the real project.

## The context

A single-site gym with a simple problem: everything — member sign-ups,
subscription tracking, cash and card payments, attendance, group billing
for partner schools — was running on a paper notebook and Excel files.
The owner had zero real-time visibility on revenue or attendance.
Front-desk staff lost 30+ seconds per member verifying status by hand.

Off-the-shelf gym SaaS existed but didn't fit: the locale wasn't
supported natively, the staff wanted a fully French UI, and the
subscription budget was tighter than a one-off custom build.

The ask was deliberately scoped: ship an operational MVP in 3 weeks,
in time for opening day, with a maintenance contract after.

## What shipped in 3 weeks

**Core flows:**
- Member sign-up with photo, emergency contact, health notes, auto-generated ID and QR code
- 6 subscription plans (day pass, week, monthly, student, quarterly, annual) with automatic expiry
- Dual-mode check-in: QR scan via tablet camera **or** text search by name / phone / ID
- Manual payment recording (cash or card) with PDF receipt generation
- Institutional groups (partner schools, clubs, associations) with reserved time slots and fixed monthly billing
- Real-time staff dashboard: monthly revenue, active subscriptions, daily check-ins, expiring-soon list, plan distribution
- 5-role RBAC (admin, manager, front desk, coach, member) with a full audit log
- Self-service member space: QR code, subscription status, personal info
- Automated transactional emails (welcome, payment confirmation, J-3 and J-0 expiration reminders)

**Infrastructure:**
- Supabase managed (Postgres + Auth + RLS + Edge Functions + Realtime + Storage)
- Vercel for the frontend
- Resend for transactional email
- Daily backup on Supabase Pro
- UptimeRobot + Sentry for monitoring

## Architecture decisions I'd make again

### 1. No custom backend

The React client hits Supabase directly. Business logic lives in Postgres
functions; async side-effects (emails, QR token rotation) in Edge
Functions. No Express/Hono layer to deploy, monitor, or rate-limit.

**Cost of this choice**: the RLS policies *have to be right*. There is
no second line of defense. I wrote automated SQL tests per role × per
table × per operation. On a 10-table schema this is tedious but finite
— and it scales better than trying to re-verify auth on every API route.

### 2. Double-layer authorization

RLS is the security boundary (source of truth). CASL on the frontend
mirrors the rule set for UX — buttons that the user can't use don't
render. Two declarations of the same permission matrix, but the
alternative (inline `if (role === 'admin')` everywhere) is how
authorization bugs get written.

### 3. Signed short-lived QR codes

First instinct: encode the member ID in a QR and call it done. Problem:
anyone can screenshot that and reuse it. Solution: a QR payload of
`GYM:memberId:token:expiresAt`, where `token` is an HMAC computed
server-side and the whole payload expires after 24h. `validate_qr_token()`
in Postgres is the single choke-point for access control.

### 4. 3-layer feature slices

Each feature has `api/` (Supabase queries), `services/` (pure business
logic), `hooks/` (TanStack Query wrappers), `components/` (UI).
Services are framework-agnostic and test in milliseconds with Vitest.

This pays off on the features where the logic is actually non-trivial:
subscription proration, QR validation, revenue aggregation, group
billing. On trivial features (audit log read-only) the services layer
is a single function — still cheap to add, still easy to explain.

### 5. Integer-only money

All amounts are `int`. No floats. Formatting is a single util wrapping
`Intl.NumberFormat`. This avoided an entire class of rounding bugs that
the original client had accumulated in Excel.

## Trade-offs

### React SPA vs Next.js

No SEO to care about (the app is private, login required), no server
components needed. Vite + React 19 SPA is faster to boot, simpler to
configure, and ships a smaller surface area. Next.js would have added
an App Router layer for nothing.

### Email/password vs magic links

Magic links would be more modern. But the member audience wasn't
necessarily comfortable with them, and email access can be
intermittent. Password + Supabase's built-in reset flow was the lower-
friction choice.

### No native mobile app

The tablet at the front desk runs the same responsive web app as the
member's phone. Cutting the native build saved ~3 weeks. If the gym
adds more sites, it becomes worth revisiting.

### Soft deletes everywhere

DELETE at the RLS layer is disabled on members, payments, and
subscriptions. Everything uses `deleted_at`. The audit log stays
consistent, and "accidentally deleted the wrong member" becomes an
UPDATE, not a restore-from-backup.

## Performance

- Target: check-in under 5 seconds end-to-end.
- Actual: QR scan → server validation → UI update in ~1.5 s on an
  average tablet + 4G.
- Dashboard KPIs: all aggregation is in Postgres functions (`get_dashboard_kpis`,
  `get_revenue_report`, `get_checkin_stats`). The client never computes sums
  in memory. `staleTime: 30_000` on KPI queries; `refetchInterval: 60_000`
  on the active dashboard.

## What would change on a v2

- **Move QR token generation from Edge Function to Postgres.** The round-trip
  through Deno added latency for nothing; a `gen_hmac(secret, payload)` with
  `pgcrypto` is simpler.
- **Add pg_cron tests.** Cron jobs are the one part of the system that is
  hard to verify locally. Today I rely on manually triggering the functions.
- **Upstream the RLS policy tests.** They live alongside the migrations;
  they should be a first-class CI step.
- **Offline-tolerant check-in.** Connectivity at the gym was reliable
  enough not to need this, but a service worker queue would make the
  front-desk UX bulletproof.

## Numbers

| | |
|---|---|
| Solo dev time | 3 weeks (MVP) |
| LOC (src/) | ~6 500 |
| SQL migrations | 15 |
| Postgres functions | 11 |
| Edge Functions | 4 |
| Feature slices | 9 (auth, members, subscriptions, check-in, payments, groups, dashboard, staff, audit) |
| Roles | 5 (admin, manager, front_desk, coach, member) |
| Tables with RLS | 100 % |

## License

MIT — see [`LICENSE`](./LICENSE).
