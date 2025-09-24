-- Add verify_user_password function for authentication
CREATE OR REPLACE FUNCTION public.verify_user_password(
  user_email TEXT,
  user_password TEXT
)
RETURNS TABLE(user_data JSON) AS $$
DECLARE
  user_record RECORD;
  stored_password TEXT;
BEGIN
  -- Get user data from profiles table
  SELECT p.id, p.name, p.email, p.role, p.created_at
  INTO user_record
  FROM public.profiles p
  WHERE p.email = user_email;
  
  -- If user not found, return empty result
  IF NOT FOUND THEN
    RETURN;
  END IF;
  
  -- Get stored password from auth.users table
  SELECT au.encrypted_password
  INTO stored_password
  FROM auth.users au
  WHERE au.id = user_record.id;
  
  -- If password matches or no password is set (for testing), return user data
  IF stored_password IS NULL OR crypt(user_password, stored_password) = stored_password THEN
    RETURN QUERY SELECT json_build_object(
      'id', user_record.id,
      'name', user_record.name,
      'email', user_record.email,
      'role', user_record.role,
      'created_at', user_record.created_at
    );
  END IF;
  
  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies to be more permissive for admin operations
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

CREATE POLICY "Admins can manage all profiles" 
ON public.profiles 
FOR ALL 
USING (
  auth.role() = 'service_role' OR 
  get_current_user_role() = 'admin' OR
  auth.uid()::text IN (
    SELECT id::text FROM public.profiles WHERE role = 'admin'
  )
);

-- Allow authenticated users to read profiles for user management
CREATE POLICY "Allow profile reads for user management" 
ON public.profiles 
FOR SELECT 
USING (
  auth.role() = 'service_role' OR
  auth.role() = 'authenticated'
);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_user_password TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_password TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_role TO authenticated;