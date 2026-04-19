-- ============================================================================
-- Migration 00012: Triggers
-- ============================================================================

-- Auto-create profile when a new user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- Audit triggers: log important changes automatically
-- ============================================================================

-- Audit: member profile changes
CREATE OR REPLACE FUNCTION public.audit_profile_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    PERFORM public.log_audit(
      'member.update',
      'member',
      NEW.id,
      jsonb_build_object(
        'old', jsonb_build_object('status', OLD.status, 'role', OLD.role),
        'new', jsonb_build_object('status', NEW.status, 'role', NEW.role)
      )
    );
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM public.log_audit('member.delete', 'member', OLD.id, NULL);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER audit_profiles
  AFTER UPDATE OR DELETE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.audit_profile_changes();

-- Audit: subscription changes
CREATE OR REPLACE FUNCTION public.audit_subscription_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.log_audit(
      'subscription.create',
      'subscription',
      NEW.id,
      jsonb_build_object('member_id', NEW.member_id, 'plan_id', NEW.plan_id)
    );
  ELSIF TG_OP = 'UPDATE' THEN
    PERFORM public.log_audit(
      'subscription.update',
      'subscription',
      NEW.id,
      jsonb_build_object('old_status', OLD.status, 'new_status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER audit_subscriptions
  AFTER INSERT OR UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.audit_subscription_changes();

-- Audit: payment recorded
CREATE OR REPLACE FUNCTION public.audit_payment_insert()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.log_audit(
    'payment.record',
    'payment',
    NEW.id,
    jsonb_build_object(
      'member_id', NEW.member_id,
      'amount', NEW.amount,
      'method', NEW.method
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER audit_payments
  AFTER INSERT ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.audit_payment_insert();

-- Audit: check-in recorded
CREATE OR REPLACE FUNCTION public.audit_checkin_insert()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.log_audit(
    'checkin.record',
    'checkin',
    NEW.id,
    jsonb_build_object('member_id', NEW.member_id, 'method', NEW.method)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER audit_check_ins
  AFTER INSERT ON public.check_ins
  FOR EACH ROW EXECUTE FUNCTION public.audit_checkin_insert();
