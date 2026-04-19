-- ============================================================================
-- Migration 00015: pg_cron jobs (requires Supabase Pro)
-- ============================================================================
-- These jobs run on Supabase Cloud only (pg_cron not available locally)
-- Uncomment when deploying to production

-- Check expired subscriptions daily at 02:00 local time
-- SELECT cron.schedule(
--   'check-subscription-status',
--   '0 2 * * *',
--   $$ SELECT public.check_subscription_status() $$
-- );

-- Trigger expiration reminders daily at 08:00 local time
-- SELECT cron.schedule(
--   'trigger-expiration-reminders',
--   '0 8 * * *',
--   $$ SELECT public.trigger_expiration_reminders() $$
-- );

-- Note: trigger_expiration_reminders() will be created when the Edge Function
-- for sending emails is implemented (Sprint 5). For now this migration is a
-- placeholder for the cron schedule.
