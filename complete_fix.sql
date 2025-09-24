-- COMPLETE FIX FOR USER MANAGEMENT
-- Execute this entire script in your Supabase SQL Editor

-- Step 1: Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile reads for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile inserts for RPC functions" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile updates for admins" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile deletes for admins" ON public.profiles;

-- Step 2: Create comprehensive RLS policies
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
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin' OR 
  id = auth.uid()
);

CREATE POLICY "Allow profile deletes for admins" 
ON public.profiles 
FOR DELETE 
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Step 3: Create the ensure_user_profile function
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

-- Step 4: Create function to list all profiles
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

-- Step 5: Create the create_user_with_password function (corrected version)
CREATE OR REPLACE FUNCTION public.create_user_with_password(
  user_email TEXT,
  user_name TEXT,
  user_password TEXT,
  user_role TEXT DEFAULT 'user',
  user_hotel_ids TEXT[] DEFAULT '{}'
)
RETURNS TEXT AS $$
DECLARE
  new_user_id UUID;
  current_user_role TEXT;
BEGIN
  -- Check if current user is admin
  SELECT role INTO current_user_role 
  FROM public.profiles 
  WHERE id = auth.uid();
  
  IF current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Apenas administradores podem criar usuários';
  END IF;
  
  -- Generate a new UUID for the user
  SELECT gen_random_uuid() INTO new_user_id;
  
  -- Create profile (Note: In production, you'd need to create the auth user via Supabase Admin API)
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (new_user_id, user_name, user_email, user_role);
  
  -- Return success message with instructions
  RETURN 'Perfil criado com ID: ' || new_user_id::TEXT || '. IMPORTANTE: O usuário deve ser criado no painel de autenticação do Supabase com este email: ' || user_email;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Erro ao criar usuário: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Grant all necessary permissions
GRANT EXECUTE ON FUNCTION public.ensure_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_all_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT ON auth.users TO authenticated;

-- Step 7: Create helper function to get current user role (if not exists)
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role 
    FROM public.profiles 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_current_user_role() TO authenticated;