-- RESOLVE FUNCTION CONFLICT - Execute this in Supabase SQL Editor
-- This script removes all conflicting function definitions and creates a single, correct one

-- Step 1: Drop all existing versions of the function to avoid conflicts
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, UUID[]);
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT, TEXT, TEXT);

-- Step 2: Create the definitive version that matches the frontend call
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
  
  -- Create profile
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (new_user_id, user_name, user_email, user_role);
  
  -- Return success message
  RETURN 'Usuário criado com sucesso! ID: ' || new_user_id::TEXT;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Erro ao criar usuário: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Grant permissions to the new function
GRANT EXECUTE ON FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) TO authenticated;

-- Step 4: Verify the function signature matches what the frontend expects
-- The frontend calls: supabase.rpc('create_user_with_password', {
--   user_email: string,
--   user_name: string, 
--   user_password: string,
--   user_role: string,
--   user_hotel_ids: []
-- })

-- This should now work without conflicts!