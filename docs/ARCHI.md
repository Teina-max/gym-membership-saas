# Technical Architecture: Gym Membership Management

## Architecture Overview

**Philosophy**: Custom web app, not a generic SaaS. Simple, direct architecture — Supabase handles the essentials (auth, DB, RLS, realtime, storage), the React frontend consumes it directly. No custom backend, no over-engineering. Every technical decision is guided by context: single-site gym, staff on tablet, potentially unstable connection, integer-only currency.

**Tech Stack Summary**:
- Frontend: React 19 + Vite + TypeScript + TanStack Router
- UI: shadcn/ui + Tailwind CSS v4
- Backend: Supabase (PostgreSQL 15, Auth, RLS, Edge Functions, Realtime, Storage)
- Auth: Supabase Auth (email/password) + CASL (frontend RBAC)
- Deployment: Vercel (frontend) + Supabase Cloud
- Runtime: Bun

## Frontend Architecture

### Core Stack

- **React 19 + Vite + TypeScript**
  - **Why**: SPA pure — pas besoin de SSR/SSG (pas de SEO, pas de page publique). Vite = dev rapide, build optimisé. React 19 pour les dernières APIs.
  - **Trade-off**: Pas de SSR → tout côté client. Acceptable car app privée (login required).

- **TanStack Router (file-based)**
  - **Why**: Type-safe routing, file-based convention, beforeLoad guards pour la protection des routes par rôle. Meilleur DX que React Router pour du TypeScript strict.
  - **Trade-off**: Moins de communauté que React Router, mais API supérieure pour notre cas.

- **shadcn/ui + Tailwind CSS v4**
  - **Why**: Composants accessibles, personnalisables, pas de vendor lock-in (code copié, pas de dépendance). Tailwind v4 pour le nouveau moteur CSS.
  - **Trade-off**: Plus de code à maintenir vs une lib de composants packagée, mais contrôle total.

### State Management

- **Global State**: React Context uniquement (auth user + CASL ability). Pas de Redux/Zustand — la complexité ne le justifie pas.
- **Server State**: TanStack Query — cache, invalidation, refetch automatique. Source de vérité = Supabase.
- **URL State**: TanStack Router search params pour filtres, pagination, recherche dans les listes (membres, paiements).
- **Form State**: react-hook-form + Zod — validation côté client avant envoi à Supabase.

### Data Fetching Strategy

```
Component → useQuery (TanStack Query) → service function → Supabase client → PostgreSQL (RLS)
Component → useMutation → service function → Supabase client → PostgreSQL (RLS) → invalidateQueries
```

- `staleTime: 60_000` par défaut (évite les refetch inutiles)
- `staleTime: 30_000` pour les KPIs dashboard
- Supabase Realtime pour les subscriptions live (check-ins, inscriptions)
- Optimistic updates sur les mutations fréquentes (check-in)

### Realtime Strategy

Supabase Realtime (WebSocket) sur 2 canaux :
- **Canal `check-ins`** : INSERT sur `check_ins` → dashboard staff voit les entrées en live
- **Canal `members`** : INSERT sur `members` → nouveau membre apparaît instantanément dans la liste staff (utile pendant l'onboarding en salle)

Implémentation via `useEffect` + `supabase.channel()` dans les hooks concernés. Pas de Realtime sur toutes les tables — uniquement là où le live apporte de la valeur.

## Backend Architecture

### API Layer

- **Pattern**: Client direct Supabase (pas d'API Routes custom)
  - **Why**: Supabase expose une API REST auto-générée depuis le schéma PostgreSQL. RLS protège les données. Pas besoin d'un backend intermédiaire.
  - **Trade-off**: Logique métier complexe → Postgres Functions (pas de serveur Node à maintenir).

- **Validation**: Zod côté frontend (avant envoi) + CHECK constraints PostgreSQL + RLS policies
- **Security**: RLS = couche de sécurité principale. Pas de rate limiting custom nécessaire (Supabase gère).

### Edge Functions (Deno/TypeScript)

Utilisées uniquement pour ce qui ne peut pas être fait côté client ou en SQL :

| Function | Rôle |
|---|---|
| `send-welcome-email` | Email de bienvenue avec QR code (Resend) |
| `send-payment-confirmation` | Confirmation de paiement (Resend) |
| `send-expiration-reminder` | Rappel J-3 et J-0 (appelé par pg_cron) |
| `generate-qr-token` | Génère le token HMAC signé pour le QR code |

### Authentication & Authorization

#### Auth (Supabase Auth)
- **Méthode**: Email + mot de passe (classique)
- **Password policy**: Minimum 8 caractères (config Supabase Auth)
- **Session**: Gérée par Supabase (cookies httpOnly, refresh token rotation automatique)
- **Pas de 2FA en v1** — évaluer en Phase 2 si le client le demande

#### Authorization (double couche)

**Couche 1 — RLS (PostgreSQL) = source de vérité sécurité**
- Auth Hook injecte le rôle dans les JWT custom claims (`app_metadata.role`)
- Chaque table a des policies explicites par rôle et par opération (SELECT/INSERT/UPDATE/DELETE)
- Le rôle est stocké dans `profiles.role`, jamais dans `user_metadata` (modifiable par l'utilisateur)

**Couche 2 — CASL (frontend) = UX**
- `defineAbilityFor(role)` dans `src/lib/casl/ability.ts`
- `<Can I="create" a="Member">` pour afficher/masquer les éléments UI
- `AbilityProvider` dans `__root.tsx`, mis à jour au login/changement de rôle
- Ne protège PAS les données — uniquement l'interface

**Matrice de permissions** :

| Action | admin | manager | front_desk | coach | member |
|---|---|---|---|---|---|
| Dashboard complet | ✅ | ✅ | ❌ | ❌ | ❌ |
| Dashboard jour (KPIs basiques) | ✅ | ✅ | ✅ | ❌ | ❌ |
| CRUD membres | ✅ | ✅ | créer/lire | lire (ses membres) | lire (soi) |
| CRUD abonnements | ✅ | ✅ | créer/lire | ❌ | lire (soi) |
| Enregistrer paiement | ✅ | ✅ | ✅ | ❌ | ❌ |
| Check-in | ✅ | ✅ | ✅ | ❌ | ❌ |
| Gérer staff | ✅ | ✅ | ❌ | ❌ | ❌ |
| Gérer groupes | ✅ | ✅ | lire | ❌ | ❌ |
| Config système | ✅ | ❌ | ❌ | ❌ | ❌ |
| Journal d'audit | ✅ | ✅ | ❌ | ❌ | ❌ |
| Supprimer (soft delete) | ✅ | ❌ | ❌ | ❌ | ❌ |

## Database Schema

### Tables principales

```
profiles
├── id (uuid, FK → auth.users.id)
├── role (enum: admin, manager, front_desk, coach, member)
├── first_name (text)
├── last_name (text)
├── phone (text)
├── email (text)
├── photo_url (text, nullable)
├── emergency_contact_name (text, nullable)
├── emergency_contact_phone (text, nullable)
├── health_notes (text, nullable)
├── member_id (text, unique, auto-generated, ex: "GYM-0001")
├── status (enum: active, inactive, expired, suspended, flagged)
├── notes (text, nullable — staff internal notes)
├── created_at (timestamptz)
├── updated_at (timestamptz)
├── deleted_at (timestamptz, nullable — soft delete)

subscription_plans
├── id (uuid)
├── name (text, ex: "Mensuel Standard")
├── slug (text, unique, ex: "monthly-standard")
├── duration_days (int, ex: 30, 90, 365)
├── price (int, ex: 85)
├── is_student (boolean, default false)
├── is_active (boolean, default true)
├── sort_order (int)
├── created_at (timestamptz)

subscriptions
├── id (uuid)
├── member_id (uuid, FK → profiles.id)
├── plan_id (uuid, FK → subscription_plans.id)
├── starts_at (timestamptz)
├── expires_at (timestamptz)
├── status (enum: active, expired, suspended, cancelled)
├── created_by (uuid, FK → profiles.id — staff who created)
├── created_at (timestamptz)

payments
├── id (uuid)
├── member_id (uuid, FK → profiles.id, nullable — null for group payments)
├── group_id (uuid, FK → groups.id, nullable)
├── subscription_id (uuid, FK → subscriptions.id, nullable)
├── amount (int)
├── method (enum: cash, card)
├── reference (text, nullable — receipt number)
├── notes (text, nullable)
├── recorded_by (uuid, FK → profiles.id — staff who recorded)
├── paid_at (timestamptz)
├── created_at (timestamptz)

check_ins
├── id (uuid)
├── member_id (uuid, FK → profiles.id)
├── checked_in_by (uuid, FK → profiles.id — staff who scanned)
├── method (enum: qr_scan, manual_search)
├── created_at (timestamptz)

groups
├── id (uuid)
├── name (text, ex: "Lycée Jean-Moulin")
├── type (enum: club, school, association, other)
├── contact_name (text — responsable)
├── contact_phone (text)
├── contact_email (text, nullable)
├── monthly_rate (int)
├── notes (text, nullable)
├── is_active (boolean, default true)
├── created_at (timestamptz)
├── updated_at (timestamptz)

group_members
├── id (uuid)
├── group_id (uuid, FK → groups.id)
├── member_id (uuid, FK → profiles.id)
├── joined_at (timestamptz)
├── left_at (timestamptz, nullable)

group_time_slots
├── id (uuid)
├── group_id (uuid, FK → groups.id)
├── day_of_week (int, 0-6)
├── start_time (time)
├── end_time (time)

audit_log
├── id (uuid)
├── user_id (uuid, FK → profiles.id)
├── action (text, ex: "member.create", "payment.record")
├── entity_type (text, ex: "member", "payment")
├── entity_id (uuid)
├── metadata (jsonb, nullable — old/new values)
├── ip_address (text, nullable)
├── created_at (timestamptz)

qr_tokens
├── id (uuid)
├── member_id (uuid, FK → profiles.id)
├── token (text, unique — HMAC signed)
├── expires_at (timestamptz)
├── created_at (timestamptz)

notification_log
├── id (uuid)
├── member_id (uuid, FK → profiles.id)
├── type (enum: welcome, payment_confirmation, expiration_reminder_3d, expiration_reminder_0d)
├── channel (enum: email)
├── status (enum: sent, failed)
├── error (text, nullable)
├── sent_at (timestamptz)
```

### Postgres Functions

| Function | Trigger/Call | Rôle |
|---|---|---|
| `handle_new_user()` | AFTER INSERT on auth.users | Crée le profil, génère member_id |
| `generate_member_id()` | Called by handle_new_user | Génère "GYM-XXXX" séquentiel |
| `get_dashboard_kpis()` | RPC call | Retourne revenus jour, membres actifs, check-ins jour, impayés |
| `get_revenue_report(period)` | RPC call | Agrégation revenus par période |
| `get_checkin_stats(days)` | RPC call | Stats check-ins sur N jours |
| `get_subscription_distribution()` | RPC call | Répartition formules (pie chart) |
| `get_expiring_subscriptions(days)` | RPC call | Abonnements expirant dans N jours |
| `check_subscription_status()` | pg_cron daily | Met à jour les statuts expirés |
| `trigger_expiration_reminders()` | pg_cron daily | Appelle Edge Function pour emails J-3 et J-0 |
| `log_audit()` | Called by triggers | Insère dans audit_log |
| `validate_qr_token(token)` | RPC call | Vérifie HMAC + expiration |

### Indexes

```sql
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_status ON profiles(status);
CREATE INDEX idx_profiles_member_id ON profiles(member_id);
CREATE INDEX idx_subscriptions_member_id ON subscriptions(member_id);
CREATE INDEX idx_subscriptions_expires_at ON subscriptions(expires_at);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_payments_member_id ON payments(member_id);
CREATE INDEX idx_payments_paid_at ON payments(paid_at);
CREATE INDEX idx_payments_group_id ON payments(group_id);
CREATE INDEX idx_check_ins_member_id ON check_ins(member_id);
CREATE INDEX idx_check_ins_created_at ON check_ins(created_at);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_member_id ON group_members(member_id);
CREATE INDEX idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_qr_tokens_token ON qr_tokens(token);
CREATE INDEX idx_qr_tokens_member_id ON qr_tokens(member_id);
CREATE INDEX idx_notification_log_member_id ON notification_log(member_id);
```

## Folder Structure

```
src/
├── lib/
│   ├── supabase/
│   │   ├── client.ts                  # singleton createClient()
│   │   └── database.types.ts          # auto-generated (bun gen-types)
│   ├── casl/
│   │   ├── ability.ts                 # defineAbilityFor(role) → Ability
│   │   └── Can.tsx                    # <Can> wrapper component
│   ├── utils/
│   │   ├── currency.ts               # formatCurrency(amount) — Intl.NumberFormat
│   │   ├── date.ts                   # toLocalTime(utcDate) — app timezone
│   │   └── qr.ts                     # generateQrPayload(memberId, token)
│   └── constants.ts                   # app-wide constants
│
├── features/
│   ├── auth/
│   │   ├── api/                       # signIn, signUp, signOut, getSession
│   │   ├── services/                  # validateCredentials, mapUserToProfile
│   │   ├── hooks/                     # useAuth, useSession
│   │   └── components/               # LoginForm, AuthGuard
│   │
│   ├── members/
│   │   ├── api/                       # fetchMembers, fetchMember, createMember, updateMember
│   │   ├── services/                  # buildMemberPayload, validateMemberData
│   │   ├── hooks/                     # useMembers, useMember, useCreateMember
│   │   └── components/               # MemberList, MemberForm, MemberCard, MemberSearch
│   │
│   ├── subscriptions/
│   │   ├── api/                       # fetchPlans, createSubscription, renewSubscription
│   │   ├── services/                  # calculateExpiry, checkEligibility, getStatusLabel
│   │   ├── hooks/                     # usePlans, useSubscription, useRenew
│   │   └── components/               # PlanSelector, SubscriptionBadge, ExpirationAlert
│   │
│   ├── check-in/
│   │   ├── api/                       # recordCheckIn, fetchCheckIns, validateQrToken
│   │   ├── services/                  # parseQrPayload, validateToken, determineAccessStatus
│   │   ├── hooks/                     # useCheckIn, useCheckInHistory, useRealtimeCheckIns
│   │   └── components/               # QrScanner, CheckInResult, CheckInHistory
│   │
│   ├── payments/
│   │   ├── api/                       # recordPayment, fetchPayments, fetchUnpaid
│   │   ├── services/                  # generateReceiptData
│   │   ├── hooks/                     # usePayments, useRecordPayment, useUnpaid
│   │   └── components/               # PaymentForm, PaymentList, ReceiptPdf
│   │
│   ├── groups/
│   │   ├── api/                       # fetchGroups, createGroup, addGroupMember
│   │   ├── services/                  # calculateGroupBilling, validateTimeSlots
│   │   ├── hooks/                     # useGroups, useGroup, useGroupMembers
│   │   └── components/               # GroupForm, GroupList, GroupMemberList, TimeSlotPicker
│   │
│   ├── dashboard/
│   │   ├── api/                       # fetchKpis, fetchRevenueReport, fetchCheckinStats
│   │   ├── services/                  # formatKpiData, buildChartData
│   │   ├── hooks/                     # useKpis, useRevenueChart, useCheckinChart
│   │   └── components/               # KpiCards, RevenueChart, CheckinChart, PlanDistribution
│   │
│   ├── staff/
│   │   ├── api/                       # fetchStaff, createStaff, updateStaffRole
│   │   ├── services/                  # validateRoleChange
│   │   ├── hooks/                     # useStaff, useCreateStaff
│   │   └── components/               # StaffList, StaffForm, RoleSelect
│   │
│   ├── audit/
│   │   ├── api/                       # fetchAuditLog
│   │   ├── hooks/                     # useAuditLog
│   │   └── components/               # AuditLogTable, AuditLogFilters
│   │
│   └── notifications/
│       ├── api/                       # fetchNotificationLog
│       ├── services/                  # buildEmailPayload
│       └── hooks/                     # useNotificationLog
│
├── components/
│   ├── ui/                            # shadcn/ui primitives (button, card, dialog, etc.)
│   └── layout/
│       ├── AdminLayout.tsx            # sidebar + header staff
│       ├── MemberLayout.tsx           # header simple membre
│       ├── Sidebar.tsx                # navigation staff (responsive)
│       └── Header.tsx                 # user menu, notifications
│
├── routes/
│   ├── __root.tsx                     # root layout + AuthProvider + AbilityProvider
│   ├── login.tsx                      # page login
│   ├── _admin/
│   │   ├── route.tsx                  # layout staff + beforeLoad guard (role check)
│   │   ├── dashboard.tsx              # KPIs + charts
│   │   ├── members/
│   │   │   ├── index.tsx              # liste membres + recherche
│   │   │   ├── $memberId.tsx          # détail membre
│   │   │   └── new.tsx                # inscription nouveau membre
│   │   ├── check-in.tsx               # page scan QR + recherche
│   │   ├── payments.tsx               # liste paiements + filtres
│   │   ├── groups/
│   │   │   ├── index.tsx              # liste groupes
│   │   │   ├── $groupId.tsx           # détail groupe
│   │   │   └── new.tsx                # nouveau groupe
│   │   ├── staff.tsx                  # gestion staff
│   │   ├── audit.tsx                  # journal d'audit
│   │   └── settings.tsx               # config système (admin only)
│   └── _member/
│       ├── route.tsx                  # layout membre + beforeLoad guard
│       └── index.tsx                  # QR code + statut abonnement + infos
│
└── hooks/
    ├── use-auth.ts                    # auth state + session
    └── use-ability.ts                 # CASL ability context

supabase/
├── migrations/
│   ├── 00001_profiles.sql
│   ├── 00002_subscription_plans.sql
│   ├── 00003_subscriptions.sql
│   ├── 00004_payments.sql
│   ├── 00005_check_ins.sql
│   ├── 00006_groups.sql
│   ├── 00007_audit_log.sql
│   ├── 00008_qr_tokens.sql
│   ├── 00009_notification_log.sql
│   ├── 00010_rls_policies.sql
│   ├── 00011_functions.sql
│   ├── 00012_triggers.sql
│   ├── 00013_indexes.sql
│   ├── 00014_seed_plans.sql
│   └── 00015_pg_cron.sql
├── seed.sql
└── functions/
    ├── send-welcome-email/index.ts
    ├── send-payment-confirmation/index.ts
    ├── send-expiration-reminder/index.ts
    └── generate-qr-token/index.ts
```

## Infrastructure & Deployment

### Hosting

- **Frontend: Vercel** (free tier)
  - **Why**: Déploiement automatique depuis GitHub, CDN global, preview deploys. Free tier largement suffisant pour une app privée (peu de trafic public).
  - **Trade-off**: Dépendance Vercel, mais migration triviale (static build).

- **Backend: Supabase Cloud**
  - **Why**: Pick the region closest to the gym's users. PostgreSQL managed, Auth, RLS, Realtime, Storage, Edge Functions — all in one.
  - **Trade-off**: Supabase Pro required for pg_cron, daily backups, and SLA. Monthly cost included in the maintenance contract.

### Background Jobs

- **pg_cron** (extension Supabase Pro):
  - `check_subscription_status()` — daily at 02:00 local
  - `trigger_expiration_reminders()` — daily at 08:00 local

### Monitoring

- **Supabase Dashboard** : métriques DB, auth, edge functions
- **UptimeRobot** (free) : check HTTPS toutes les 5 min + alerte email/SMS
- **Sentry** (free tier) : error tracking frontend
- **Resend Dashboard** : délivrabilité emails

### Storage

- **Supabase Storage** : photos membres uniquement
  - Bucket `member-photos`, RLS policies, max 2MB/image
  - Resize côté client avant upload (compression)

## Architecture Decision Records

### ADR-001: React SPA vs Next.js
- **Context**: Choix du framework frontend
- **Decision**: React 19 + Vite (SPA) au lieu de Next.js
- **Alternatives**: Next.js (App Router), Remix
- **Rationale**: Pas de SEO nécessaire (app privée, login required). Pas de SSR/SSG utile. Vite = build plus rapide, config plus simple. Supabase gère le backend — pas besoin d'API Routes Next.js.
- **Consequences**: Pas de Server Components, tout côté client. Acceptable pour notre cas d'usage.

### ADR-002: Supabase direct vs API backend custom
- **Context**: Comment le frontend communique avec la DB
- **Decision**: Client Supabase direct (supabase-js) + RLS
- **Alternatives**: API Express/Hono intermédiaire, tRPC
- **Rationale**: Supabase expose une API REST auto-générée, protégée par RLS. Logique métier complexe dans Postgres Functions. Un backend intermédiaire n'apporte rien et ajoute de la latence + maintenance.
- **Consequences**: La sécurité repose entièrement sur RLS — les policies doivent être rigoureuses et testées.

### ADR-003: CASL pour le RBAC frontend
- **Context**: Comment gérer l'affichage conditionnel selon le rôle
- **Decision**: CASL (@casl/ability + @casl/react)
- **Alternatives**: Custom hook `usePermissions()`, conditions manuelles
- **Rationale**: 5 rôles avec des permissions granulaires → CASL offre une API déclarative (`<Can I="create" a="Member">`), centralisée dans un seul fichier. Plus maintenable que des `if (role === 'admin')` partout.
- **Consequences**: Dépendance supplémentaire (~8KB gzip). Acceptable pour le gain en lisibilité.

### ADR-004: QR code signé (HMAC) vs statique
- **Context**: Sécurité du check-in par QR code
- **Decision**: QR code contient `memberId:token:expires`, token signé HMAC-SHA256 côté serveur
- **Alternatives**: QR statique (juste le member_id), QR avec JWT
- **Rationale**: Un QR statique est un simple identifiant — screenshot = fraude. Le token HMAC est validé côté serveur, expiré après 24h, et renouvelé automatiquement. Plus léger qu'un JWT.
- **Consequences**: Nécessite une Edge Function pour la génération + une Postgres Function pour la validation. Le membre doit ouvrir l'app pour rafraîchir son QR si expiré.

### ADR-005: Couche services dans les features
- **Context**: Où placer la logique métier frontend
- **Decision**: Dossier `services/` dans chaque feature (entre api/ et hooks/)
- **Alternatives**: Tout dans les hooks, tout dans les api/
- **Rationale**: Séparer la logique métier (calculs, validations, transformations) des appels Supabase (api/) et du state management (hooks/). Les services sont des fonctions pures, facilement testables unitairement.
- **Consequences**: Un dossier de plus par feature. Justifié quand la logique est non triviale (paiements, abonnements, QR). Pas obligatoire pour les features simples (audit log).

### ADR-006: Email/password vs magic link
- **Context**: Member authentication method
- **Decision**: Email + classic password
- **Alternatives**: Magic link, SMS OTP
- **Rationale**: Members are not necessarily comfortable with magic links. Password is the most familiar pattern. Email access can also be intermittent.
- **Consequences**: Need to handle password reset. Supabase Auth handles it natively.

## Cost Estimation

### Monthly production cost

| Service | Plan | Cost |
|---|---|---|
| Supabase | Pro | $25/month |
| Vercel | Free / Hobby | $0-20/month |
| Resend | Free (3 000 emails/month) | $0 |
| UptimeRobot | Free | $0 |
| Sentry | Free (5K events/month) | $0 |
| Domain | .com | ~$15/year |
| **Total** | | **~$25-45/month** |

### Free tier limits to watch

- **Resend**: 3 000 emails/month → enough for ~200 members (welcome + confirmations + reminders). Beyond → $20/month.
- **Supabase Storage**: 1GB included in Pro → enough for member photos.
- **Vercel**: 100GB bandwidth/month → more than enough (private app).

## Implementation Priority

### Phase 1A: Foundation (jours 1-3)
1. Setup projet (Vite + React + TypeScript + Tailwind + shadcn/ui + TanStack Router + TanStack Query)
2. Setup Supabase local (supabase init + config)
3. Migrations : tables profiles, subscription_plans, subscriptions
4. RLS policies pour les 3 premières tables
5. Auth : login/logout + AuthProvider + route guards
6. CASL : ability factory + AbilityProvider + Can component
7. Layout admin (sidebar + header) + layout membre

### Phase 1B: Core Features (jours 4-10)
1. Feature membres : CRUD + recherche + liste + détail
2. Feature abonnements : sélection formule + création + suivi
3. Feature paiements : enregistrement + liste + reçu PDF
4. Feature check-in : scan QR + recherche texte + résultat visuel
5. Migrations : payments, check_ins, qr_tokens
6. Edge Functions : QR token generation + validation
7. Espace membre : QR code + statut

### Phase 1C: Groupes & Dashboard (jours 11-16)
1. Feature groupes : CRUD + membres + créneaux + paiements
2. Dashboard : KPIs + graphiques (Postgres Functions + Recharts)
3. Feature staff : gestion rôles
5. Audit log

### Phase 1D: Notifications & Polish (jours 17-21)
1. Edge Functions : emails (bienvenue, confirmation, rappels)
2. pg_cron : check expiration + trigger rappels
3. Notification log
4. Seed data réaliste
5. Tests RLS (SQL) + tests intégration (Vitest) + E2E (Playwright, 5 flows critiques)
6. Deploy Vercel + Supabase Cloud
7. Monitoring (UptimeRobot + Sentry)
