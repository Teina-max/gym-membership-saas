-- ============================================================================
-- Migration 00001: profiles table
-- ============================================================================

-- Custom types
CREATE TYPE public.user_role AS ENUM ('admin', 'manager', 'front_desk', 'coach', 'member');
CREATE TYPE public.member_status AS ENUM ('active', 'inactive', 'expired', 'suspended', 'flagged');

-- Sequence for member_id generation (GYM-0001, GYM-0002, ...)
CREATE SEQUENCE public.member_id_seq START WITH 1;

-- Profiles table (extends auth.users)
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.user_role NOT NULL DEFAULT 'member',
  first_name text NOT NULL,
  last_name text NOT NULL,
  phone text,
  email text NOT NULL,
  photo_url text,
  emergency_contact_name text,
  emergency_contact_phone text,
  health_notes text,
  member_id text UNIQUE NOT NULL DEFAULT ('GYM-' || lpad(nextval('public.member_id_seq')::text, 4, '0')),
  status public.member_status NOT NULL DEFAULT 'active',
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
