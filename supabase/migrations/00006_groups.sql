-- ============================================================================
-- Migration 00006: groups, group_members, group_time_slots tables
-- ============================================================================

CREATE TYPE public.group_type AS ENUM ('club', 'school', 'association', 'other');

CREATE TABLE public.groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type public.group_type NOT NULL DEFAULT 'other',
  contact_name text NOT NULL,
  contact_phone text NOT NULL,
  contact_email text,
  monthly_rate int NOT NULL CHECK (monthly_rate >= 0),
  notes text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER groups_updated_at
  BEFORE UPDATE ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE public.group_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  member_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  UNIQUE (group_id, member_id)
);

CREATE TABLE public.group_time_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  day_of_week int NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time time NOT NULL,
  end_time time NOT NULL,
  CHECK (end_time > start_time)
);

-- Add FK from payments to groups (deferred from migration 00004)
ALTER TABLE public.payments
  ADD CONSTRAINT payments_group_id_fkey
  FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE SET NULL;

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_time_slots ENABLE ROW LEVEL SECURITY;
