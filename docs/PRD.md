# Product Requirements Document: Gym Membership Management

## Product Vision

**Problem Statement**
A single-site gym relies entirely on notebooks and Excel to track members, subscriptions, payments, and access. Off-the-shelf SaaS products don't fit: specific locale (French UI, configurable currency/timezone), need for self-hosted data (RGPD), and a limited budget. The owner has zero real-time visibility on revenue, churn, or attendance.

**Solution**
A custom web app that centralizes the full operations of the gym: members, subscriptions (6 plans), payments, QR-based access control, institutional groups, and a real-time staff dashboard. Two spaces: Staff (operations) and Member (self-service).

**Success Criteria**
- Staff uses the software exclusively from opening day (zero parallel notebook/Excel)
- 100% of members have a digital profile + working QR code
- Owner confirms satisfaction at the J+7 post-delivery review
- Zero untracked payment — every transaction is recorded in the system

## Target Users

### Persona 1: Owner / Admin
- **Role**: Gym owner, final decision-maker
- **Pain Points**:
  - No visibility on revenue, unpaid balances, attendance
  - Impossible to steer the business without reliable data
  - Manual management is time-consuming and error-prone
- **Motivations**: Professional tool from day one, data-driven decisions
- **Goals**: Dashboard with revenue, active members, check-ins

### Persona 2: Front Desk Staff
- **Role**: Reception staff working on a tablet
- **Pain Points**:
  - Manually verifying if a member has paid or is active
  - Paper-based sign-up flow is slow and error-prone
  - No access log
- **Motivations**: Fast, simple tool for member flow
- **Goals**: Check-in in < 5 seconds (QR scan or search), fast sign-up, traced payments

### Persona 3: Member
- **Role**: Gym member
- **Pain Points**:
  - Doesn't know their subscription expiration date
  - Has to ask staff for any info
- **Motivations**: Autonomy — see their status, QR code, info
- **Goals**: Display their QR code at reception, know their subscription status

### Persona 4: Coach
- **Role**: Fitness coach running classes
- **Pain Points**:
  - Doesn't know their assigned members
  - No visibility on their sessions
- **Motivations**: Quick access to member list and schedule
- **Goals**: View assigned members and daily sessions

## Core Features (MVP — Phase 1)

### Must-Have Features

#### 1. Member management
**Description**: Full member sign-up (profile, photo, plan, emergency contact, health notes). Automatic generation of a unique ID and QR code sent by email. Statuses: active, inactive, expired, suspended, flagged.
**User Value**: Replaces the paper notebook with a reliable database and complete history.
**Success Metric**: 100% of members have a digital profile with a QR code from sign-up.

#### 2. Subscriptions & plans
**Description**: 6 pre-configured plans (Day Pass, Weekly Pass, Monthly Standard, Monthly Student, Quarterly, Annual). Start/end date management, renewal, suspension.
**User Value**: Clear pricing, automatic expiry tracking, expiration alerts.
**Success Metric**: Zero undetected expired subscription — the system always alerts.

#### 3. QR code check-in
**Description**: Dual mode: QR scan via tablet camera or text search (name, ID, phone). Visual alerts if subscription expired/suspended/flagged. Complete access history (date, time).
**User Value**: Access control in < 5 seconds, full audit trail, anti-fraud protection (HMAC-signed QR token).
**Success Metric**: Average check-in time < 5 seconds. Zero untracked entry.

#### 4. Payments & billing
**Description**: Manual payment recording by staff (cash, card). PDF receipt/invoice generation. Unpaid-balance tracking. Revenue reports by day/week/month.
**User Value**: Complete financial traceability, end of "forgotten" payments. Staff records every payment at the point of sale.
**Success Metric**: 100% of payments recorded in the system.

#### 5. Groups & institutions
**Description**: Group accounts with a designated contact. Reserved time slots. Fixed monthly rates. Group payment tracking with unpaid alerts. Custom rates for clubs/associations.
**User Value**: Structured management of institutional clients (clubs, schools, associations) that represent significant recurring revenue.
**Success Metric**: Each group has a contact, a time slot, and active payment tracking.

#### 6. Staff dashboard
**Description**: Real-time view: daily revenue, active members, daily check-ins, unpaid list. Charts: monthly revenue (12 months), daily check-ins (30 days), plan distribution.
**User Value**: One-glance business overview — the owner sees business health at any time.
**Success Metric**: The owner checks the dashboard daily.

#### 7. Role-based access control
**Description**: 4 roles with distinct permissions (Admin, Manager, Front Desk, Coach). Audit log: full traceability of all staff actions. CASL on the frontend + RLS on the server.
**User Value**: Each staff member sees only what concerns them. Audit trail in case of dispute.
**Success Metric**: Zero unauthorized access detected. Complete audit log.

#### 8. Member space
**Description**: Large QR code for reception presentation. Subscription status and expiration date. Personal info read-only.
**User Value**: Member autonomy — no need to ask staff.
**Success Metric**: Members use their digital QR code (no physical card needed).

#### 9. Automated email notifications
**Description**: Welcome email (ID + QR code + login link). Confirmation after each payment. Expiration reminders at J-3 and J-0.
**User Value**: Automated communication — staff no longer chases manually.
**Success Metric**: 100% of emails delivered successfully (Resend monitoring).

### Should-Have Features (Phase 2 — 3 to 6 months after launch)

- **Coaching**: per-session and bundle sales (Pack 4 at -10%, Pack 8 at -20%), remaining-session tracking
- **Class schedule**: bookings, attendance tracking
- **Advanced reports**: growth, attendance, peak hours, PDF/Excel export
- **Enriched member space**: payment history, class booking
- **WhatsApp gateway**: multi-step automatic reminders
- **Advanced groups**: detailed billing, contact management, automatic alerts

### Nice-to-Have Features (Phase 3 — on request)

- NFC badge or smartcard check-in
- Personalized training program assigned by coach
- Session log and member progress tracking

## User Flows

### Flow 1: New member sign-up (Front Desk)
1. Staff clicks "New member"
2. Fills the form (name, first name, phone, email, photo, emergency contact, health notes)
3. Selects a subscription plan
4. Records the payment (cash or card)
5. System generates the ID + QR code
6. Welcome email sent automatically to the member
7. Member appears as "active" in the list

### Flow 2: Member check-in (Front Desk)
1. Member presents QR code on their phone
2. Staff scans with the tablet (or searches by name/phone)
3. System displays profile with large status indicator:
   - Green = active → check-in recorded
   - Orange = expiring soon → check-in + alert
   - Red = expired/suspended/flagged → access denied + action required
4. Access is logged in history

### Flow 3: Group/institution sign-up (Admin/Manager)
1. Admin creates a group account (name, contact, contact info)
2. Defines monthly rate and reserved time slots
3. Adds members to the group (individually or in bulk)
4. System bills the contact monthly
5. Automatic alerts on unpaid balances

### Flow 4: Member self-service (Member)
1. Member logs in (link received by email)
2. Sees their QR code in large format (ready to scan)
3. Consults subscription status and expiration date
4. Consults personal info

## Out of Scope (v1 — Phase 1)

Explicitly NOT included in the MVP:
- **Native mobile app** (iOS/Android) — app is responsive, not native
- **Online payment** (online card, PayPal) — only manual payment recording is included
- **Marketing website / public page** — no landing page
- **Accounting integration** — no link with third-party tools
- **Class schedule** — deferred to Phase 2
- **Coaching & session packs** — deferred to Phase 2
- **Advanced reports (PDF/Excel export)** — deferred to Phase 2
- **WhatsApp** — deferred to Phase 2
- **NFC / smartcard** — deferred to Phase 3
- **Multi-language** — French only
- **Multi-site** — single site

## Success Metrics

**Primary Metrics**:
- **Staff adoption**: 100% of operations (sign-ups, check-ins, payments) go through the software from J+1
- **Data reliability**: 0 untracked payment, 0 unlogged check-in
- **Client satisfaction**: positive feedback from owner at the J+7 post-delivery review

**Secondary Metrics**:
- **Check-in time**: < 5 seconds on average
- **Email deliverability rate**: > 95%
- **Uptime**: 99.9% (automated monitoring)
- **Support response time**: < 48h (contractual)

## Technical Constraints

- **Currency**: EUR — integer amounts, `Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' })` (configurable)
- **Timezone**: Europe/Paris — stored in UTC, displayed in local (configurable per deployment)
- **Language**: French (UI), English (code)
- **Primary device**: tablet at the front desk → mobile-first mandatory
- **Connectivity**: optionally unstable → optimize performance, minimize requests
- **Security**: RLS on 100% of tables, RGPD (French territory), HMAC-signed QR codes
- **Stack**: React 19 + Vite + Supabase + TanStack Router + shadcn/ui + CASL
