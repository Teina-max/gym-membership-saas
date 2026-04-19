-- ============================================================================
-- Migration 00011: Postgres functions
-- ============================================================================

-- ============================================================================
-- handle_new_user: creates profile after auth.users insert
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'first_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'last_name', ''),
    COALESCE(
      (NEW.raw_app_meta_data ->> 'role')::public.user_role,
      'member'::public.user_role
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- get_dashboard_kpis: returns key metrics for the dashboard
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_dashboard_kpis()
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'revenue_month', COALESCE((
      SELECT SUM(amount)
      FROM public.payments
      WHERE paid_at >= date_trunc('month', now())
    ), 0),
    'active_subscriptions', (
      SELECT COUNT(*)
      FROM public.subscriptions
      WHERE status = 'active'
        AND expires_at > now()
    ),
    'checkins_today', (
      SELECT COUNT(*)
      FROM public.check_ins
      WHERE created_at >= date_trunc('day', now() AT TIME ZONE 'Europe/Paris') AT TIME ZONE 'Europe/Paris'
    ),
    'expiring_7days', (
      SELECT COUNT(*)
      FROM public.subscriptions
      WHERE status = 'active'
        AND expires_at BETWEEN now() AND now() + interval '7 days'
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- get_revenue_report: monthly revenue for the last N months
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_revenue_report(months_back int DEFAULT 12)
RETURNS TABLE (month text, revenue bigint) AS $$
BEGIN
  RETURN QUERY
  SELECT
    to_char(d.month_start, 'YYYY-MM') AS month,
    COALESCE(SUM(p.amount), 0)::bigint AS revenue
  FROM generate_series(
    date_trunc('month', now()) - ((months_back - 1) || ' months')::interval,
    date_trunc('month', now()),
    '1 month'::interval
  ) AS d(month_start)
  LEFT JOIN public.payments p
    ON p.paid_at >= d.month_start
    AND p.paid_at < d.month_start + interval '1 month'
  GROUP BY d.month_start
  ORDER BY d.month_start;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- get_checkin_stats: daily check-ins for last N days
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_checkin_stats(days_back int DEFAULT 30)
RETURNS TABLE (day date, count bigint) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.day::date,
    COALESCE(COUNT(ci.id), 0)::bigint AS count
  FROM generate_series(
    (now() - ((days_back - 1) || ' days')::interval)::date,
    now()::date,
    '1 day'::interval
  ) AS d(day)
  LEFT JOIN public.check_ins ci
    ON ci.created_at::date = d.day::date
  GROUP BY d.day
  ORDER BY d.day;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- get_subscription_distribution: plan breakdown for pie chart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_subscription_distribution()
RETURNS TABLE (plan_name text, count bigint) AS $$
BEGIN
  RETURN QUERY
  SELECT
    sp.name AS plan_name,
    COUNT(s.id)::bigint AS count
  FROM public.subscriptions s
  JOIN public.subscription_plans sp ON sp.id = s.plan_id
  WHERE s.status = 'active'
    AND s.expires_at > now()
  GROUP BY sp.name, sp.sort_order
  ORDER BY sp.sort_order;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- get_expiring_subscriptions: subscriptions expiring within N days
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_expiring_subscriptions(days_ahead int DEFAULT 7)
RETURNS TABLE (
  subscription_id uuid,
  member_id uuid,
  first_name text,
  last_name text,
  email text,
  plan_name text,
  expires_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id AS subscription_id,
    p.id AS member_id,
    p.first_name,
    p.last_name,
    p.email,
    sp.name AS plan_name,
    s.expires_at
  FROM public.subscriptions s
  JOIN public.profiles p ON p.id = s.member_id
  JOIN public.subscription_plans sp ON sp.id = s.plan_id
  WHERE s.status = 'active'
    AND s.expires_at BETWEEN now() AND now() + (days_ahead || ' days')::interval
    AND p.deleted_at IS NULL
  ORDER BY s.expires_at;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- check_subscription_status: daily cron job to expire subscriptions
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_subscription_status()
RETURNS void AS $$
BEGIN
  -- Mark expired subscriptions
  UPDATE public.subscriptions
  SET status = 'expired'
  WHERE status = 'active'
    AND expires_at < now();

  -- Update member profiles with no active subscription
  UPDATE public.profiles p
  SET status = 'expired'
  WHERE p.status = 'active'
    AND p.role = 'member'
    AND NOT EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.member_id = p.id
        AND s.status = 'active'
        AND s.expires_at > now()
    )
    AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.member_id = p.id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- log_audit: generic audit logging function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.log_audit(
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_metadata jsonb DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  INSERT INTO public.audit_log (user_id, action, entity_type, entity_id, metadata, ip_address)
  VALUES (
    auth.uid(),
    p_action,
    p_entity_type,
    p_entity_id,
    p_metadata,
    current_setting('request.headers', true)::jsonb ->> 'x-forwarded-for'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- validate_qr_token: validates HMAC token + expiration
-- ============================================================================

CREATE OR REPLACE FUNCTION public.validate_qr_token(p_token text)
RETURNS jsonb AS $$
DECLARE
  v_token_record RECORD;
  v_profile RECORD;
  v_subscription RECORD;
BEGIN
  -- Find the token
  SELECT * INTO v_token_record
  FROM public.qr_tokens
  WHERE token = p_token;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', false, 'reason', 'Token invalide');
  END IF;

  -- Check expiration
  IF v_token_record.expires_at < now() THEN
    RETURN jsonb_build_object('valid', false, 'reason', 'Token expiré');
  END IF;

  -- Get member profile
  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = v_token_record.member_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', false, 'reason', 'Membre introuvable');
  END IF;

  -- Check member status
  IF v_profile.status NOT IN ('active') THEN
    RETURN jsonb_build_object(
      'valid', false,
      'reason', 'Membre ' || v_profile.status::text,
      'member', jsonb_build_object(
        'id', v_profile.id,
        'first_name', v_profile.first_name,
        'last_name', v_profile.last_name,
        'member_id', v_profile.member_id,
        'status', v_profile.status
      )
    );
  END IF;

  -- Get active subscription
  SELECT * INTO v_subscription
  FROM public.subscriptions
  WHERE member_id = v_token_record.member_id
    AND status = 'active'
    AND expires_at > now()
  ORDER BY expires_at DESC
  LIMIT 1;

  RETURN jsonb_build_object(
    'valid', true,
    'member', jsonb_build_object(
      'id', v_profile.id,
      'first_name', v_profile.first_name,
      'last_name', v_profile.last_name,
      'member_id', v_profile.member_id,
      'status', v_profile.status,
      'photo_url', v_profile.photo_url
    ),
    'subscription', CASE
      WHEN v_subscription IS NOT NULL THEN jsonb_build_object(
        'id', v_subscription.id,
        'expires_at', v_subscription.expires_at,
        'status', v_subscription.status
      )
      ELSE NULL
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
