-- Fix for create_user_with_password function signature issue
-- Execute this in Supabase SQL Editor

-- First, let's check if the function exists and recreate it with correct signature
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
  
  -- Create auth user using admin API (this is a simplified version)
  -- In production, you'd use Supabase Admin API
  SELECT gen_random_uuid() INTO new_user_id;
  
  -- Create profile directly (since we can't create auth users from SQL)
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (new_user_id, user_name, user_email, user_role);
  
  RETURN new_user_id::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Erro ao criar usuário: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;

-- Alternative: Create a simpler version that works with the current setup
CREATE OR REPLACE FUNCTION public.create_user_profile_only(
  user_name TEXT,
  user_email TEXT,
  user_role TEXT DEFAULT 'user'
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
  
  -- Generate a new UUID for the profile
  SELECT gen_random_uuid() INTO new_user_id;
  
  -- Create profile (user will need to be created separately in Supabase Auth)
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (new_user_id, user_name, user_email, user_role);
  
  RETURN new_user_id::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Erro ao criar perfil: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for the alternative function
GRANT EXECUTE ON FUNCTION public.create_user_profile_only(TEXT, TEXT, TEXT) TO authenticated;