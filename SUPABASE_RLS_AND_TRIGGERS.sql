-- =====================================================
-- SUPABASE RLS POLICIES AND TRIGGERS SETUP
-- Fix "Session expired" issue in WasteFreeBD
-- =====================================================

-- Copy these SQL commands and run them in your Supabase SQL Editor:
-- Dashboard > SQL Editor > New Query > Paste and Run

-- =====================================================
-- 1. ENABLE ROW LEVEL SECURITY ON user_profiles
-- =====================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;


-- =====================================================
-- 2. CREATE RLS POLICIES FOR user_profiles
-- =====================================================

-- Drop existing policies if they exist (for clean setup)
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

-- Policy 1: Allow users to SELECT (view) their own profile
CREATE POLICY "Users can view own profile" 
ON public.user_profiles 
FOR SELECT 
USING ( auth.uid() = id );

-- Policy 2: Allow users to INSERT their own profile
CREATE POLICY "Users can insert own profile" 
ON public.user_profiles 
FOR INSERT 
WITH CHECK ( auth.uid() = id );

-- Policy 3: Allow users to UPDATE their own profile
CREATE POLICY "Users can update own profile" 
ON public.user_profiles 
FOR UPDATE 
USING ( auth.uid() = id )
WITH CHECK ( auth.uid() = id );


-- =====================================================
-- 3. AUTO-CREATE user_profiles WHEN USER SIGNS UP
-- =====================================================

-- Drop existing function and trigger if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create function to automatically insert profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, full_name, role, created_at, updated_at)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'full_name', new.email),
    COALESCE(new.raw_user_meta_data->>'role', 'user'),
    now(),
    now()
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to run the function after user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- =====================================================
-- 4. VERIFY SETUP (Check if everything works)
-- =====================================================

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'user_profiles';
-- Expected: rowsecurity = true

-- List all policies on user_profiles
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'user_profiles';
-- Expected: 3 policies (SELECT, INSERT, UPDATE)

-- Check if trigger exists
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';
-- Expected: 1 row showing the trigger


-- =====================================================
-- 5. OPTIONAL: CREATE PROFILES FOR EXISTING USERS
-- =====================================================

-- If you have existing users without profiles, run this:
INSERT INTO public.user_profiles (id, full_name, role, created_at, updated_at)
SELECT 
  au.id,
  COALESCE(au.raw_user_meta_data->>'full_name', au.email) as full_name,
  COALESCE(au.raw_user_meta_data->>'role', 'user') as role,
  au.created_at,
  now()
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE up.id IS NULL;
-- This creates profiles for users who don't have one yet


-- =====================================================
-- 6. OPTIONAL: DISABLE RLS FOR TESTING (NOT RECOMMENDED)
-- =====================================================

-- ONLY use this for debugging if you want to test without RLS:
-- ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- Remember to re-enable it after testing:
-- ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;


-- =====================================================
-- DONE! 
-- Now restart your Flutter app and try updating your profile.
-- =====================================================
