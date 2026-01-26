-- Fix for user_profiles table to work with custom signin table
-- Execute this in your Supabase SQL Editor

-- 1. Drop the existing user_profiles table if it exists (WARNING: This will delete data!)
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- 2. Create user_profiles table that references signin table (not auth.users)
CREATE TABLE public.user_profiles (
  id bigint NOT NULL,
  full_name text NULL,
  phone text NULL,
  address text NULL,
  profile_photo text NULL,
  role text NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES public.signin (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- 3. Create index on id for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON public.user_profiles USING btree (id) TABLESPACE pg_default;

-- 4. Create function to update updated_at timestamp (if not exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. Create trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at 
BEFORE UPDATE ON public.user_profiles 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- 6. Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own profile" ON public.user_profiles
FOR UPDATE USING (true);

CREATE POLICY "Users can delete own profile" ON public.user_profiles
FOR DELETE USING (true);

-- 8. Grant permissions
GRANT ALL ON public.user_profiles TO anon, authenticated;
