-- ============================================================================
-- Migration 00008: qr_tokens table
-- ============================================================================

CREATE TABLE public.qr_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token text UNIQUE NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.qr_tokens ENABLE ROW LEVEL SECURITY;
