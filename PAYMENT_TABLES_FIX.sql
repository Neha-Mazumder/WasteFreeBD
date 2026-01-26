-- Complete Payment Tables Setup for WasteFreeBD
-- Execute this in your Supabase SQL Editor

-- Step 1: Drop existing tables if they have issues (CAUTION: removes data)
-- Uncomment these lines ONLY if you want to start fresh:
-- DROP TABLE IF EXISTS public.payments CASCADE;
-- DROP TABLE IF EXISTS public.financial_records CASCADE;

-- Step 2: Create payments table
CREATE TABLE IF NOT EXISTS public.payments (
  id BIGSERIAL PRIMARY KEY,
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  description TEXT,
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Create financial_records table
CREATE TABLE IF NOT EXISTS public.financial_records (
  id BIGSERIAL PRIMARY KEY,
  date DATE DEFAULT CURRENT_DATE,
  revenue NUMERIC(12,2) DEFAULT 0,
  profit NUMERIC(12,2) DEFAULT 0,
  costs NUMERIC(12,2) DEFAULT 0,
  category TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: Enable RLS
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_records ENABLE ROW LEVEL SECURITY;

-- Step 5: Create permissive policies (allow everything for anon users)
DO $$
BEGIN
  -- Payments policies
  DROP POLICY IF EXISTS "Enable all for payments" ON public.payments;
  CREATE POLICY "Enable all for payments" ON public.payments FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
  
  -- Financial records policies
  DROP POLICY IF EXISTS "Enable all for financial_records" ON public.financial_records;
  CREATE POLICY "Enable all for financial_records" ON public.financial_records FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
END $$;

-- Step 6: Grant full permissions
GRANT ALL ON public.payments TO anon;
GRANT ALL ON public.payments TO authenticated;
GRANT ALL ON public.financial_records TO anon;
GRANT ALL ON public.financial_records TO authenticated;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Step 7: Verify tables exist (run this to check)
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('payments', 'financial_records');
