-- ============================================================================
-- Migration 00009: notification_log table
-- ============================================================================

CREATE TYPE public.notification_type AS ENUM (
  'welcome',
  'payment_confirmation',
  'expiration_reminder_3d',
  'expiration_reminder_0d'
);

CREATE TYPE public.notification_channel AS ENUM ('email');

CREATE TYPE public.notification_status AS ENUM ('sent', 'failed');

CREATE TABLE public.notification_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type public.notification_type NOT NULL,
  channel public.notification_channel NOT NULL DEFAULT 'email',
  status public.notification_status NOT NULL,
  error text,
  sent_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;
