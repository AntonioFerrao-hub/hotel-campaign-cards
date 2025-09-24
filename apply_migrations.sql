-- EXECUTE THIS SQL IN YOUR SUPABASE SQL EDITOR
-- This consolidates all the necessary migrations to fix user management

-- Step 1: Fix RLS policies for profiles table
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;

-- Create comprehensive policies for profiles table
CREATE POLICY "Allow profile reads for authenticated users" 
ON public.profiles 
FOR SELECT 
USING (auth.role() = 'authenticated');

CREATE POLICY "Allow profile inserts for RPC functions" 
ON public.profiles 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Allow profile updates for admins" 
ON public.profiles 
FOR UPDATE 
USING (
  get_current_user_role() = 'admin' OR 
  id = auth.uid()
);

CREATE POLICY "Allow profile deletes for admins" 
ON public.profiles 
FOR DELETE 
USING (get_current_user_role() = 'admin');

-- Step 2: Create the ensure_user_profile function
CREATE OR REPLACE FUNCTION public.ensure_user_profile()
RETURNS TABLE(user_id UUID, user_email TEXT, user_name TEXT, user_role TEXT) AS $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
  profile_exists BOOLEAN;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'No authenticated user found';
  END IF;
  
  SELECT email INTO current_user_email 
  FROM auth.users 
  WHERE id = current_user_id;
  
  SELECT EXISTS(
    SELECT 1 FROM public.profiles 
    WHERE id = current_user_id
  ) INTO profile_exists;
  
  IF NOT profile_exists THEN
    INSERT INTO public.profiles (id, name, email, role)
    VALUES (
      current_user_id,
      COALESCE(current_user_email, 'Usuário'),
      current_user_email,
      'admin'
    );
  END IF;
  
  RETURN QUERY
  SELECT 
    p.id as user_id,
    p.email as user_email,
    p.name as user_name,
    p.role as user_role
  FROM public.profiles p
  WHERE p.id = current_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create function to list all profiles
CREATE OR REPLACE FUNCTION public.list_all_profiles()
RETURNS TABLE(
  profile_id UUID,
  profile_name TEXT,
  profile_email TEXT,
  profile_role TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.email,
    p.role,
    p.created_at,
    p.updated_at
  FROM public.profiles p
  ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.ensure_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_all_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT SELECT, INSERT ON public.profiles TO authenticated;
GRANT SELECT ON auth.users TO authenticated;

-- Step 5: Ensure create_user_with_password function is properly configured
-- Note: The function signature should match the actual function definition
ALTER FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) SECURITY DEFINER;