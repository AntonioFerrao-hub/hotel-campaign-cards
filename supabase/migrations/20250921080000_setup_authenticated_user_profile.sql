-- Setup authenticated user profile and list existing users

-- First, let's create a function to get or create the current user's profile
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
      'admin' -- Set as admin since they're creating users
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

-- Create a function to list all profiles
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.ensure_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_all_profiles() TO authenticated;