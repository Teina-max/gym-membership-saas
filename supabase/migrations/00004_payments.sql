-- ============================================================================
-- Migration 00004: payments table
-- ============================================================================

CREATE TYPE public.payment_method AS ENUM ('cash', 'card');

CREATE TABLE public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  group_id uuid, -- FK added in 00006 after groups table exists
  subscription_id uuid REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  amount int NOT NULL CHECK (amount > 0),
  method public.payment_method NOT NULL,
  reference text,
  notes text,
  recorded_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  paid_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
