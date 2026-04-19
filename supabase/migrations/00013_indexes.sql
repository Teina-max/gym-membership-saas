-- ============================================================================
-- Migration 00013: Indexes
-- ============================================================================

-- profiles
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_status ON public.profiles(status);
CREATE INDEX idx_profiles_member_id ON public.profiles(member_id);
CREATE INDEX idx_profiles_deleted_at ON public.profiles(deleted_at) WHERE deleted_at IS NULL;

-- subscriptions
CREATE INDEX idx_subscriptions_member_id ON public.subscriptions(member_id);
CREATE INDEX idx_subscriptions_expires_at ON public.subscriptions(expires_at);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX idx_subscriptions_active ON public.subscriptions(member_id, status) WHERE status = 'active';

-- payments
CREATE INDEX idx_payments_member_id ON public.payments(member_id);
CREATE INDEX idx_payments_paid_at ON public.payments(paid_at);
CREATE INDEX idx_payments_group_id ON public.payments(group_id);

-- check_ins
CREATE INDEX idx_check_ins_member_id ON public.check_ins(member_id);
CREATE INDEX idx_check_ins_created_at ON public.check_ins(created_at);

-- groups / group_members
CREATE INDEX idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX idx_group_members_member_id ON public.group_members(member_id);

-- audit_log
CREATE INDEX idx_audit_log_user_id ON public.audit_log(user_id);
CREATE INDEX idx_audit_log_entity ON public.audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_created_at ON public.audit_log(created_at);

-- qr_tokens
CREATE INDEX idx_qr_tokens_token ON public.qr_tokens(token);
CREATE INDEX idx_qr_tokens_member_id ON public.qr_tokens(member_id);

-- notification_log
CREATE INDEX idx_notification_log_member_id ON public.notification_log(member_id);
