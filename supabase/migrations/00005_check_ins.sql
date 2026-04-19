-- ============================================================================
-- Migration 00005: check_ins table
-- ============================================================================

CREATE TYPE public.checkin_method AS ENUM ('qr_scan', 'manual_search');

CREATE TABLE public.check_ins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  checked_in_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  method public.checkin_method NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
