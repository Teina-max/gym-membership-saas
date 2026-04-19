-- ============================================================================
-- Migration 00010: RLS policies for all tables
-- ============================================================================
-- Helper: extract role from JWT custom claims
-- The Auth Hook sets app_metadata.role on the JWT

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS public.user_role AS $$
  SELECT COALESCE(
    (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'role')::public.user_role,
    'member'::public.user_role
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean AS $$
  SELECT public.get_user_role() IN ('admin', 'manager', 'front_desk', 'coach');
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ============================================================================
-- profiles
-- ============================================================================

-- Staff can read all profiles (not deleted)
CREATE POLICY profiles_staff_select ON public.profiles
  FOR SELECT TO authenticated
  USING (
    public.is_staff()
    AND deleted_at IS NULL
  );

-- Members can only read their own profile
CREATE POLICY profiles_member_select ON public.profiles
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    AND deleted_at IS NULL
  );

-- Admin and manager can insert profiles
CREATE POLICY profiles_admin_manager_insert ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    public.get_user_role() IN ('admin', 'manager', 'front_desk')
  );

-- Admin and manager can update profiles
CREATE POLICY profiles_admin_manager_update ON public.profiles
  FOR UPDATE TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager')
  )
  WITH CHECK (
    public.get_user_role() IN ('admin', 'manager')
  );

-- Front desk can update limited fields (handled at app level, policy allows update)
CREATE POLICY profiles_front_desk_update ON public.profiles
  FOR UPDATE TO authenticated
  USING (
    public.get_user_role() = 'front_desk'
    AND role = 'member'
  )
  WITH CHECK (
    public.get_user_role() = 'front_desk'
    AND role = 'member'
  );

-- Members can update their own non-sensitive fields
CREATE POLICY profiles_member_update ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
    AND status = (SELECT p.status FROM public.profiles p WHERE p.id = auth.uid())
  );

-- Only admin can soft delete (set deleted_at)
CREATE POLICY profiles_admin_delete ON public.profiles
  FOR DELETE TO authenticated
  USING (
    public.get_user_role() = 'admin'
  );

-- ============================================================================
-- subscription_plans
-- ============================================================================

-- Everyone authenticated can read active plans
CREATE POLICY plans_select ON public.subscription_plans
  FOR SELECT TO authenticated
  USING (true);

-- Only admin can manage plans
CREATE POLICY plans_admin_insert ON public.subscription_plans
  FOR INSERT TO authenticated
  WITH CHECK (public.get_user_role() = 'admin');

CREATE POLICY plans_admin_update ON public.subscription_plans
  FOR UPDATE TO authenticated
  USING (public.get_user_role() = 'admin')
  WITH CHECK (public.get_user_role() = 'admin');

CREATE POLICY plans_admin_delete ON public.subscription_plans
  FOR DELETE TO authenticated
  USING (public.get_user_role() = 'admin');

-- ============================================================================
-- subscriptions
-- ============================================================================

-- Staff can read all subscriptions
CREATE POLICY subscriptions_staff_select ON public.subscriptions
  FOR SELECT TO authenticated
  USING (public.is_staff());

-- Members can read their own subscriptions
CREATE POLICY subscriptions_member_select ON public.subscriptions
  FOR SELECT TO authenticated
  USING (member_id = auth.uid());

-- Admin, manager, front_desk can create subscriptions
CREATE POLICY subscriptions_staff_insert ON public.subscriptions
  FOR INSERT TO authenticated
  WITH CHECK (
    public.get_user_role() IN ('admin', 'manager', 'front_desk')
  );

-- Admin, manager can update subscriptions
CREATE POLICY subscriptions_admin_update ON public.subscriptions
  FOR UPDATE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_user_role() IN ('admin', 'manager'));

-- ============================================================================
-- payments
-- ============================================================================

-- Staff (except coach) can read all payments
CREATE POLICY payments_staff_select ON public.payments
  FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'front_desk')
  );

-- Members can read their own payments
CREATE POLICY payments_member_select ON public.payments
  FOR SELECT TO authenticated
  USING (member_id = auth.uid());

-- Admin, manager, front_desk can record payments
CREATE POLICY payments_staff_insert ON public.payments
  FOR INSERT TO authenticated
  WITH CHECK (
    public.get_user_role() IN ('admin', 'manager', 'front_desk')
  );

-- Admin can update payments (corrections)
CREATE POLICY payments_admin_update ON public.payments
  FOR UPDATE TO authenticated
  USING (public.get_user_role() = 'admin')
  WITH CHECK (public.get_user_role() = 'admin');

-- ============================================================================
-- check_ins
-- ============================================================================

-- Staff (except coach) can read all check-ins
CREATE POLICY checkins_staff_select ON public.check_ins
  FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'front_desk')
  );

-- Members can read their own check-ins
CREATE POLICY checkins_member_select ON public.check_ins
  FOR SELECT TO authenticated
  USING (member_id = auth.uid());

-- Admin, manager, front_desk can create check-ins
CREATE POLICY checkins_staff_insert ON public.check_ins
  FOR INSERT TO authenticated
  WITH CHECK (
    public.get_user_role() IN ('admin', 'manager', 'front_desk')
  );

-- ============================================================================
-- groups
-- ============================================================================

-- Staff can read all groups
CREATE POLICY groups_staff_select ON public.groups
  FOR SELECT TO authenticated
  USING (public.is_staff());

-- Admin, manager can manage groups
CREATE POLICY groups_admin_insert ON public.groups
  FOR INSERT TO authenticated
  WITH CHECK (public.get_user_role() IN ('admin', 'manager'));

CREATE POLICY groups_admin_update ON public.groups
  FOR UPDATE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_user_role() IN ('admin', 'manager'));

CREATE POLICY groups_admin_delete ON public.groups
  FOR DELETE TO authenticated
  USING (public.get_user_role() = 'admin');

-- ============================================================================
-- group_members
-- ============================================================================

-- Staff can read all group memberships
CREATE POLICY group_members_staff_select ON public.group_members
  FOR SELECT TO authenticated
  USING (public.is_staff());

-- Members can see their own group memberships
CREATE POLICY group_members_member_select ON public.group_members
  FOR SELECT TO authenticated
  USING (member_id = auth.uid());

-- Admin, manager can manage group members
CREATE POLICY group_members_admin_insert ON public.group_members
  FOR INSERT TO authenticated
  WITH CHECK (public.get_user_role() IN ('admin', 'manager'));

CREATE POLICY group_members_admin_update ON public.group_members
  FOR UPDATE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_user_role() IN ('admin', 'manager'));

CREATE POLICY group_members_admin_delete ON public.group_members
  FOR DELETE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'));

-- ============================================================================
-- group_time_slots
-- ============================================================================

-- Staff can read all time slots
CREATE POLICY group_time_slots_staff_select ON public.group_time_slots
  FOR SELECT TO authenticated
  USING (public.is_staff());

-- Admin, manager can manage time slots
CREATE POLICY group_time_slots_admin_insert ON public.group_time_slots
  FOR INSERT TO authenticated
  WITH CHECK (public.get_user_role() IN ('admin', 'manager'));

CREATE POLICY group_time_slots_admin_update ON public.group_time_slots
  FOR UPDATE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_user_role() IN ('admin', 'manager'));

CREATE POLICY group_time_slots_admin_delete ON public.group_time_slots
  FOR DELETE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'));

-- ============================================================================
-- audit_log
-- ============================================================================

-- Only admin and manager can read audit log
CREATE POLICY audit_log_admin_select ON public.audit_log
  FOR SELECT TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'));

-- Insert is done by triggers via SECURITY DEFINER functions (no direct insert policy needed for users)
-- But we allow service_role and authenticated with staff role for manual inserts
CREATE POLICY audit_log_staff_insert ON public.audit_log
  FOR INSERT TO authenticated
  WITH CHECK (public.is_staff());

-- ============================================================================
-- qr_tokens
-- ============================================================================

-- Members can read their own tokens
CREATE POLICY qr_tokens_member_select ON public.qr_tokens
  FOR SELECT TO authenticated
  USING (member_id = auth.uid());

-- Staff can read tokens (for validation)
CREATE POLICY qr_tokens_staff_select ON public.qr_tokens
  FOR SELECT TO authenticated
  USING (public.is_staff());

-- Tokens are created by Edge Functions (service_role), no user insert policy needed
-- But allow staff for manual token management
CREATE POLICY qr_tokens_staff_insert ON public.qr_tokens
  FOR INSERT TO authenticated
  WITH CHECK (public.is_staff());

CREATE POLICY qr_tokens_staff_delete ON public.qr_tokens
  FOR DELETE TO authenticated
  USING (public.is_staff());

-- ============================================================================
-- notification_log
-- ============================================================================

-- Admin and manager can read notification logs
CREATE POLICY notification_log_admin_select ON public.notification_log
  FOR SELECT TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager'));

-- Members can see their own notifications
CREATE POLICY notification_log_member_select ON public.notification_log
  FOR SELECT TO authenticated
  USING (member_id = auth.uid());

-- Insert via service_role (Edge Functions), allow staff for manual entries
CREATE POLICY notification_log_staff_insert ON public.notification_log
  FOR INSERT TO authenticated
  WITH CHECK (public.is_staff());
