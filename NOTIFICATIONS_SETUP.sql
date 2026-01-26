-- Notifications System Setup for WasteFreeBD
-- Execute these queries in your Supabase SQL Editor

-- 1. Create the broadcast_table_changes function (if not already exists)
-- This function will be triggered to send real-time updates
CREATE OR REPLACE FUNCTION public.broadcast_table_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  PERFORM
    pg_notify(
      CONCAT('table_change:', TG_TABLE_NAME),
      json_build_object(
        'type', TG_OP,
        'record', row_to_json(NEW),
        'old_record', row_to_json(OLD)
      )::text
    );
  RETURN COALESCE(NEW, OLD);
END;
$function$;

-- 2. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid not null default gen_random_uuid (),
  title text not null,
  type text not null check (type in ('pickup_request', 'dustbin_full', 'other')),
  status text not null default 'pending' check (status in ('pending', 'completed')),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint notifications_pkey primary key (id)
) TABLESPACE pg_default;

-- 3. Enable RLS (Row Level Security) on notifications table
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 4. Create index on status and created_at for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_status_created ON public.notifications(status, created_at DESC);

-- 5. Create RLS policy to allow public read access
CREATE POLICY "Allow public read notifications" ON public.notifications
  FOR SELECT
  USING (true);

-- 6. Create RLS policy to allow public insert
CREATE POLICY "Allow public insert notifications" ON public.notifications
  FOR INSERT
  WITH CHECK (true);

-- 7. Create RLS policy to allow public update
CREATE POLICY "Allow public update notifications" ON public.notifications
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- 8. Create RLS policy to allow public delete
CREATE POLICY "Allow public delete notifications" ON public.notifications
  FOR DELETE
  USING (true);

-- 9. Create trigger for real-time broadcasting of notification changes
-- This trigger will fire on INSERT, UPDATE, DELETE operations
CREATE TRIGGER notifications_broadcast_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.broadcast_table_changes();

-- 10. Optional: Create a materialized view for notification statistics (for performance)
CREATE OR REPLACE VIEW public.notification_stats AS
SELECT
  COUNT(*) as total_notifications,
  COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
  COUNT(*) FILTER (WHERE type = 'pickup_request') as pickup_request_count,
  COUNT(*) FILTER (WHERE type = 'dustbin_full') as dustbin_full_count
FROM public.notifications;

-- 11. Example: Insert sample notifications (for testing)
-- INSERT INTO public.notifications (title, type, status) VALUES
-- ('Pickup request from Dhanmondi', 'pickup_request', 'pending'),
-- ('Dustbin full alert at Gulshan', 'dustbin_full', 'pending'),
-- ('Pickup request from Mirpur', 'pickup_request', 'completed');

-- 12. Optional: Create an audit log table to track notification changes
CREATE TABLE IF NOT EXISTS public.notification_audit_log (
  id uuid not null default gen_random_uuid (),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  action text not null,
  old_data jsonb,
  new_data jsonb,
  changed_at timestamp with time zone not null default now(),
  constraint notification_audit_log_pkey primary key (id)
) TABLESPACE pg_default;

-- 13. Create trigger to log notification changes
CREATE OR REPLACE FUNCTION public.log_notification_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO public.notification_audit_log (notification_id, action, old_data, changed_at)
    VALUES (OLD.id, 'DELETE', row_to_json(OLD), now());
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO public.notification_audit_log (notification_id, action, old_data, new_data, changed_at)
    VALUES (NEW.id, 'UPDATE', row_to_json(OLD), row_to_json(NEW), now());
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO public.notification_audit_log (notification_id, action, new_data, changed_at)
    VALUES (NEW.id, 'INSERT', row_to_json(NEW), now());
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$function$;

CREATE TRIGGER notification_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.log_notification_changes();
