-- Create payments table if missing with recommended schema
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payments') THEN
    CREATE TABLE public.payments (
      id SERIAL PRIMARY KEY,
      amount NUMERIC(12,2) NOT NULL,
      status VARCHAR(50) NOT NULL DEFAULT 'pending',
      paid_at TIMESTAMP WITH TIME ZONE,
      metadata JSONB DEFAULT '{}'::jsonb,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  END IF;
END$$;

-- Ensure updated_at trigger exists for payments
CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_payments_updated_at') THEN
    CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON public.payments
    FOR EACH ROW EXECUTE PROCEDURE public.update_timestamp();
  END IF;
END$$;

-- Ensure unique index on financial_records.date
CREATE UNIQUE INDEX IF NOT EXISTS financial_records_date_idx ON public.financial_records(date);

-- Create or replace trigger function to upsert completed payments into financial_records
CREATE OR REPLACE FUNCTION public.payments_to_financial_records()
RETURNS TRIGGER AS $$
DECLARE
  pay_date date;
  amt numeric := COALESCE(NEW.amount, 0);
  prev_status text := NULL;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    prev_status := OLD.status;
  END IF;

  -- Only proceed when the new status is 'completed' and it was not completed before
  IF NEW.status IS DISTINCT FROM 'completed' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND prev_status = 'completed' THEN
    RETURN NEW;
  END IF;

  pay_date := (COALESCE(NEW.paid_at, NOW()))::date;

  INSERT INTO public.financial_records (date, revenue, profit, costs, created_at)
  VALUES (pay_date, amt, amt, 0, NOW())
  ON CONFLICT (date) DO UPDATE
    SET revenue = public.financial_records.revenue + EXCLUDED.revenue,
        profit  = public.financial_records.profit  + EXCLUDED.profit,
        created_at = LEAST(public.financial_records.created_at, EXCLUDED.created_at);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to payments (replace if exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payments') THEN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'payments_financial_trigger') THEN
      DROP TRIGGER payments_financial_trigger ON public.payments;
    END IF;

    CREATE TRIGGER payments_financial_trigger
    AFTER INSERT OR UPDATE ON public.payments
    FOR EACH ROW EXECUTE FUNCTION public.payments_to_financial_records();
  END IF;
END$$;
