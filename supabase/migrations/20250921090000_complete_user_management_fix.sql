-- Complete user management fix - consolidating all necessary changes

-- First, ensure we have the correct RLS policies
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
WITH CHECK (true); -- This allows the RPC functions to insert

CREATE POLICY "Allow profile updates for admins" 
ON public.profiles 
FOR UPDATE 
USING (
  get_current_user_role() = 'admin' OR 
  id = auth.uid() -- Users can update their own profile
);

CREATE POLICY "Allow profile deletes for admins" 
ON public.profiles 
FOR DELETE 
USING (get_current_user_role() = 'admin');

-- Ensure the create_user_with_password function has proper permissions
ALTER FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) SECURITY DEFINER;

-- Create the ensure_user_profile function
CREATE OR REPLACE FUNCTION public.ensure_user_profile()
RETURNS TABLE(user_id UUID, user_email TEXT, user_name TEXT, user_role TEXT) AS $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
  profile_exists BOOLEAN;
BEGIN
  -- Get current authenticated user
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'No authenticated user found';
  END IF;
  
  -- Get user email from auth.users
  SELECT email INTO current_user_email 
  FROM auth.users 
  WHERE id = current_user_id;
  
  -- Check if profile already exists
  SELECT EXISTS(
    SELECT 1 FROM public.profiles 
    WHERE id = current_user_id
  ) INTO profile_exists;
  
  -- If profile doesn't exist, create it
  IF NOT profile_exists THEN
    INSERT INTO public.profiles (id, name, email, role)
    VALUES (
      current_user_id,
      COALESCE(current_user_email, 'Usuário'),
      current_user_email,
      'admin' -- Set as admin since they're managing users
    );
  END IF;
  
  -- Return the user profile
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

-- Create function to list all profiles
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

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.ensure_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_all_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;

-- Ensure proper access to tables
GRANT SELECT, INSERT ON public.profiles TO authenticated;
GRANT SELECT ON auth.users TO authenticated;