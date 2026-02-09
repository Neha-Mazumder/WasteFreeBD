-- Notifications Table for WasteFreeBD
-- Execute this in your Supabase SQL Editor

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  type text NOT NULL DEFAULT 'pickup_request',
  status text NOT NULL DEFAULT 'pending',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_type_check CHECK (type IN ('pickup_request', 'dustbin_full', 'general')),
  CONSTRAINT notifications_status_check CHECK (status IN ('pending', 'completed'))
) TABLESPACE pg_default;

-- 2. Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- 3. Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies (allow all operations for now)
CREATE POLICY "Allow all operations on notifications" ON public.notifications
FOR ALL USING (true) WITH CHECK (true);

-- 5. Grant permissions
GRANT ALL ON public.notifications TO anon, authenticated;

-- 6. Enable Realtime for notifications table (IMPORTANT for real-time updates!)
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Test: Insert a sample notification (optional)
-- INSERT INTO public.notifications (title, type, status) VALUES 
-- ('Test Pickup Request from Dhaka', 'pickup_request', 'pending');
