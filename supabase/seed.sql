-- ============================================================================
-- Seed data: realistic test data for local development
-- ============================================================================
-- Run with: supabase db reset (applies migrations + seed)
--
-- This seed creates test users via Supabase Auth, which triggers handle_new_user()
-- to auto-create profiles. We then update profiles with complete data.
-- ============================================================================

-- Disable audit triggers during seeding (auth.uid() is NULL in seed context)
ALTER TABLE public.profiles DISABLE TRIGGER audit_profiles;
ALTER TABLE public.subscriptions DISABLE TRIGGER audit_subscriptions;
ALTER TABLE public.payments DISABLE TRIGGER audit_payments;
ALTER TABLE public.check_ins DISABLE TRIGGER audit_check_ins;

-- ============================================================================
-- 1. Create auth users (password: "password123" for all test accounts)
-- ============================================================================

-- Admin
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'admin@fitclub.test',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"], "role": "admin"}'::jsonb,
  '{"first_name": "Alice", "last_name": "Martin"}'::jsonb,
  now(), now(), 'authenticated', 'authenticated'
);

-- Manager
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000000',
  'manager@fitclub.test',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"], "role": "manager"}'::jsonb,
  '{"first_name": "Bruno", "last_name": "Dubois"}'::jsonb,
  now(), now(), 'authenticated', 'authenticated'
);

-- Front desk
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000000',
  'accueil@fitclub.test',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"], "role": "front_desk"}'::jsonb,
  '{"first_name": "Claire", "last_name": "Bernard"}'::jsonb,
  now(), now(), 'authenticated', 'authenticated'
);

-- Coach
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  '00000000-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000000',
  'coach@fitclub.test',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"], "role": "coach"}'::jsonb,
  '{"first_name": "David", "last_name": "Leroy"}'::jsonb,
  now(), now(), 'authenticated', 'authenticated'
);

-- Members (10 generic French names)
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES
  ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000000', 'emma.durand@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Emma", "last_name": "Durand"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000000', 'lucas.petit@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Lucas", "last_name": "Petit"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000000', 'lea.moreau@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Léa", "last_name": "Moreau"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000000', 'hugo.laurent@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Hugo", "last_name": "Laurent"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000000', 'chloe.simon@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Chloé", "last_name": "Simon"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000000', 'nathan.roux@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Nathan", "last_name": "Roux"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000000', 'camille.garnier@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Camille", "last_name": "Garnier"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000000', 'jules.faure@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Jules", "last_name": "Faure"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000000', 'manon.blanc@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Manon", "last_name": "Blanc"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000000', 'paul.girard@mail.test', crypt('password123', gen_salt('bf')), now(), '{"provider": "email", "providers": ["email"], "role": "member"}'::jsonb, '{"first_name": "Paul", "last_name": "Girard"}'::jsonb, now(), now(), 'authenticated', 'authenticated');

-- Create identities for auth (required by Supabase Auth)
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
SELECT
  id, id,
  jsonb_build_object('sub', id, 'email', email),
  'email', id, now(), now(), now()
FROM auth.users;

-- ============================================================================
-- 2. Update profiles with complete data
-- ============================================================================

UPDATE public.profiles SET phone = '06 12 00 00 01' WHERE id = '00000000-0000-0000-0000-000000000001';
UPDATE public.profiles SET phone = '06 12 00 00 02' WHERE id = '00000000-0000-0000-0000-000000000002';
UPDATE public.profiles SET phone = '06 12 00 00 03' WHERE id = '00000000-0000-0000-0000-000000000003';
UPDATE public.profiles SET phone = '06 12 00 00 04' WHERE id = '00000000-0000-0000-0000-000000000004';

UPDATE public.profiles SET
  phone = '06 12 10 00 01',
  emergency_contact_name = 'Sophie Durand',
  emergency_contact_phone = '06 12 10 00 02'
WHERE id = '00000000-0000-0000-0000-000000000010';

UPDATE public.profiles SET
  phone = '06 12 10 00 03',
  emergency_contact_name = 'Thomas Petit',
  emergency_contact_phone = '06 12 10 00 04'
WHERE id = '00000000-0000-0000-0000-000000000011';

UPDATE public.profiles SET
  phone = '06 12 10 00 05',
  emergency_contact_name = 'Julie Moreau',
  emergency_contact_phone = '06 12 10 00 06'
WHERE id = '00000000-0000-0000-0000-000000000012';

UPDATE public.profiles SET
  phone = '06 12 10 00 07',
  emergency_contact_name = 'Marie Laurent',
  emergency_contact_phone = '06 12 10 00 08',
  health_notes = 'Asthme léger — a un inhalateur'
WHERE id = '00000000-0000-0000-0000-000000000013';

UPDATE public.profiles SET
  phone = '06 12 10 00 09',
  emergency_contact_name = 'Pierre Simon',
  emergency_contact_phone = '06 12 10 00 10'
WHERE id = '00000000-0000-0000-0000-000000000014';

UPDATE public.profiles SET phone = '06 12 10 00 11' WHERE id = '00000000-0000-0000-0000-000000000015';
UPDATE public.profiles SET phone = '06 12 10 00 12' WHERE id = '00000000-0000-0000-0000-000000000016';
UPDATE public.profiles SET phone = '06 12 10 00 13' WHERE id = '00000000-0000-0000-0000-000000000017';
UPDATE public.profiles SET phone = '06 12 10 00 14' WHERE id = '00000000-0000-0000-0000-000000000018';
UPDATE public.profiles SET phone = '06 12 10 00 15' WHERE id = '00000000-0000-0000-0000-000000000019';

-- ============================================================================
-- 3. Subscriptions (varied plans and statuses)
-- ============================================================================

-- Get plan IDs
DO $$
DECLARE
  plan_monthly uuid;
  plan_student uuid;
  plan_quarterly uuid;
  plan_annual uuid;
  plan_weekly uuid;
  staff_id uuid := '00000000-0000-0000-0000-000000000003'; -- front_desk created these
BEGIN
  SELECT id INTO plan_monthly FROM public.subscription_plans WHERE slug = 'monthly-standard';
  SELECT id INTO plan_student FROM public.subscription_plans WHERE slug = 'monthly-student';
  SELECT id INTO plan_quarterly FROM public.subscription_plans WHERE slug = 'quarterly';
  SELECT id INTO plan_annual FROM public.subscription_plans WHERE slug = 'annual';
  SELECT id INTO plan_weekly FROM public.subscription_plans WHERE slug = 'weekly-pass';

  -- Active monthly subscriptions
  INSERT INTO public.subscriptions (member_id, plan_id, starts_at, expires_at, status, created_by) VALUES
    ('00000000-0000-0000-0000-000000000010', plan_monthly, now() - interval '10 days', now() + interval '20 days', 'active', staff_id),
    ('00000000-0000-0000-0000-000000000011', plan_monthly, now() - interval '5 days', now() + interval '25 days', 'active', staff_id),
    ('00000000-0000-0000-0000-000000000012', plan_student, now() - interval '15 days', now() + interval '15 days', 'active', staff_id);

  -- Quarterly and annual
  INSERT INTO public.subscriptions (member_id, plan_id, starts_at, expires_at, status, created_by) VALUES
    ('00000000-0000-0000-0000-000000000013', plan_quarterly, now() - interval '30 days', now() + interval '60 days', 'active', staff_id),
    ('00000000-0000-0000-0000-000000000014', plan_annual, now() - interval '60 days', now() + interval '305 days', 'active', staff_id);

  -- Expiring soon (within 7 days)
  INSERT INTO public.subscriptions (member_id, plan_id, starts_at, expires_at, status, created_by) VALUES
    ('00000000-0000-0000-0000-000000000015', plan_monthly, now() - interval '27 days', now() + interval '3 days', 'active', staff_id),
    ('00000000-0000-0000-0000-000000000016', plan_weekly, now() - interval '5 days', now() + interval '2 days', 'active', staff_id);

  -- Expired subscription
  INSERT INTO public.subscriptions (member_id, plan_id, starts_at, expires_at, status, created_by) VALUES
    ('00000000-0000-0000-0000-000000000017', plan_monthly, now() - interval '45 days', now() - interval '15 days', 'expired', staff_id);

  -- Suspended member
  INSERT INTO public.subscriptions (member_id, plan_id, starts_at, expires_at, status, created_by) VALUES
    ('00000000-0000-0000-0000-000000000018', plan_monthly, now() - interval '20 days', now() + interval '10 days', 'suspended', staff_id);

  -- No subscription yet (member 19)
END $$;

-- Update member statuses to match subscriptions
UPDATE public.profiles SET status = 'expired' WHERE id = '00000000-0000-0000-0000-000000000017';
UPDATE public.profiles SET status = 'suspended' WHERE id = '00000000-0000-0000-0000-000000000018';
UPDATE public.profiles SET status = 'inactive' WHERE id = '00000000-0000-0000-0000-000000000019';

-- ============================================================================
-- 4. Payments
-- ============================================================================

DO $$
DECLARE
  staff_id uuid := '00000000-0000-0000-0000-000000000003';
BEGIN
  INSERT INTO public.payments (member_id, amount, method, recorded_by, paid_at, reference) VALUES
    ('00000000-0000-0000-0000-000000000010',  85, 'cash', staff_id, now() - interval '10 days', 'REC-001'),
    ('00000000-0000-0000-0000-000000000011',  85, 'card', staff_id, now() - interval '5 days',  'REC-002'),
    ('00000000-0000-0000-0000-000000000012',  65, 'cash', staff_id, now() - interval '15 days', 'REC-003'),
    ('00000000-0000-0000-0000-000000000013', 230, 'card', staff_id, now() - interval '30 days', 'REC-004'),
    ('00000000-0000-0000-0000-000000000014', 850, 'card', staff_id, now() - interval '60 days', 'REC-005'),
    ('00000000-0000-0000-0000-000000000015',  85, 'cash', staff_id, now() - interval '27 days', 'REC-006'),
    ('00000000-0000-0000-0000-000000000016',  50, 'cash', staff_id, now() - interval '5 days',  'REC-007'),
    ('00000000-0000-0000-0000-000000000017',  85, 'cash', staff_id, now() - interval '45 days', 'REC-008');
END $$;

-- ============================================================================
-- 5. Check-ins (last 7 days)
-- ============================================================================

DO $$
DECLARE
  staff_id uuid := '00000000-0000-0000-0000-000000000003';
BEGIN
  INSERT INTO public.check_ins (member_id, checked_in_by, method, created_at) VALUES
    -- Today
    ('00000000-0000-0000-0000-000000000010', staff_id, 'qr_scan', now() - interval '2 hours'),
    ('00000000-0000-0000-0000-000000000011', staff_id, 'qr_scan', now() - interval '3 hours'),
    ('00000000-0000-0000-0000-000000000013', staff_id, 'manual_search', now() - interval '1 hour'),
    -- Yesterday
    ('00000000-0000-0000-0000-000000000010', staff_id, 'qr_scan', now() - interval '1 day' - interval '4 hours'),
    ('00000000-0000-0000-0000-000000000012', staff_id, 'qr_scan', now() - interval '1 day' - interval '3 hours'),
    ('00000000-0000-0000-0000-000000000014', staff_id, 'qr_scan', now() - interval '1 day' - interval '2 hours'),
    ('00000000-0000-0000-0000-000000000015', staff_id, 'manual_search', now() - interval '1 day' - interval '5 hours'),
    -- 2 days ago
    ('00000000-0000-0000-0000-000000000010', staff_id, 'qr_scan', now() - interval '2 days' - interval '3 hours'),
    ('00000000-0000-0000-0000-000000000011', staff_id, 'qr_scan', now() - interval '2 days' - interval '4 hours'),
    ('00000000-0000-0000-0000-000000000013', staff_id, 'qr_scan', now() - interval '2 days' - interval '2 hours'),
    ('00000000-0000-0000-0000-000000000016', staff_id, 'qr_scan', now() - interval '2 days' - interval '5 hours'),
    -- 3 days ago
    ('00000000-0000-0000-0000-000000000010', staff_id, 'qr_scan', now() - interval '3 days' - interval '3 hours'),
    ('00000000-0000-0000-0000-000000000012', staff_id, 'manual_search', now() - interval '3 days' - interval '4 hours'),
    ('00000000-0000-0000-0000-000000000014', staff_id, 'qr_scan', now() - interval '3 days' - interval '2 hours'),
    -- 5 days ago
    ('00000000-0000-0000-0000-000000000011', staff_id, 'qr_scan', now() - interval '5 days' - interval '3 hours'),
    ('00000000-0000-0000-0000-000000000015', staff_id, 'qr_scan', now() - interval '5 days' - interval '4 hours');
END $$;

-- ============================================================================
-- 6. Group example: local school partnership
-- ============================================================================

INSERT INTO public.groups (id, name, type, contact_name, contact_phone, contact_email, monthly_rate, notes)
VALUES (
  '00000000-0000-0000-0000-000000000100',
  'Lycée Jean-Moulin',
  'school',
  'Isabelle Rousseau',
  '06 12 50 00 01',
  'contact@lycee-jeanmoulin.test',
  450,
  'Convention annuelle — 15 élèves max, créneaux mardi et jeudi 16h-18h'
);

-- Add some members to the group
INSERT INTO public.group_members (group_id, member_id) VALUES
  ('00000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000012'),
  ('00000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000016');

-- Time slots: Tuesday and Thursday 16h-18h
INSERT INTO public.group_time_slots (group_id, day_of_week, start_time, end_time) VALUES
  ('00000000-0000-0000-0000-000000000100', 2, '16:00', '18:00'),
  ('00000000-0000-0000-0000-000000000100', 4, '16:00', '18:00');

-- Group payment
INSERT INTO public.payments (group_id, amount, method, recorded_by, paid_at, reference, notes)
VALUES (
  '00000000-0000-0000-0000-000000000100',
  450,
  'card',
  '00000000-0000-0000-0000-000000000003',
  now() - interval '15 days',
  'GRP-001',
  'Paiement mensuel Lycée Jean-Moulin — mars 2026'
);

-- Re-enable audit triggers
ALTER TABLE public.profiles ENABLE TRIGGER audit_profiles;
ALTER TABLE public.subscriptions ENABLE TRIGGER audit_subscriptions;
ALTER TABLE public.payments ENABLE TRIGGER audit_payments;
ALTER TABLE public.check_ins ENABLE TRIGGER audit_check_ins;
