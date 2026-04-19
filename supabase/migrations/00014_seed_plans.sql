-- ============================================================================
-- Migration 00014: Seed subscription plans (6 formules)
-- ============================================================================

INSERT INTO public.subscription_plans (name, slug, duration_days, price, is_student, sort_order)
VALUES
  ('Pass Jour',        'day-pass',          1,   15, false, 1),
  ('Pass Semaine',     'weekly-pass',       7,   50, false, 2),
  ('Mensuel Standard', 'monthly-standard', 30,   85, false, 3),
  ('Mensuel Étudiant', 'monthly-student',  30,   65, true,  4),
  ('Trimestriel',      'quarterly',        90,  230, false, 5),
  ('Annuel',           'annual',          365,  850, false, 6);
