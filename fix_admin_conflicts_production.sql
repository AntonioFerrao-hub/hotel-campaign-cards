-- ========================================
-- CORREÇÃO DE CONFLITOS ADMINISTRATIVOS
-- Execute este script no Supabase Dashboard > SQL Editor
-- ========================================

-- 1. CRIAR FUNÇÃO DE AUDITORIA DE ADMINISTRADORES
CREATE OR REPLACE FUNCTION public.audit_admin_users()
RETURNS TABLE(
  issue_type TEXT,
  user_id UUID,
  name TEXT,
  email TEXT,
  created_at TIMESTAMPTZ,
  recommendation TEXT
) AS $$
DECLARE
  admin_count INTEGER;
  oldest_admin RECORD;
BEGIN
  -- Contar administradores
  SELECT COUNT(*) INTO admin_count
  FROM public.profiles
  WHERE role = 'admin';
  
  -- Se há múltiplos admins, retornar informações
  IF admin_count > 1 THEN
    -- Encontrar o admin mais antigo
    SELECT p.id, p.name, p.email, p.created_at
    INTO oldest_admin
    FROM public.profiles p
    WHERE p.role = 'admin'
    ORDER BY p.created_at ASC
    LIMIT 1;
    
    -- Retornar todos os admins com recomendações
    RETURN QUERY
    SELECT 
      CASE 
        WHEN p.id = oldest_admin.id THEN 'primary_admin'
        ELSE 'duplicate_admin'
      END::TEXT as issue_type,
      p.id,
      p.name,
      p.email,
      p.created_at,
      CASE 
        WHEN p.id = oldest_admin.id THEN 'Manter como administrador principal'
        ELSE 'Considerar alterar para role "user" ou "manager"'
      END::TEXT as recommendation
    FROM public.profiles p
    WHERE p.role = 'admin'
    ORDER BY p.created_at ASC;
  ELSE
    -- Retornar o único admin ou indicar que não há admins
    IF admin_count = 1 THEN
      RETURN QUERY
      SELECT 
        'single_admin'::TEXT,
        p.id,
        p.name,
        p.email,
        p.created_at,
        'Configuração adequada - um único administrador'::TEXT
      FROM public.profiles p
      WHERE p.role = 'admin';
    ELSE
      RETURN QUERY
      SELECT 
        'no_admin'::TEXT,
        NULL::UUID,
        'N/A'::TEXT,
        'N/A'::TEXT,
        NULL::TIMESTAMPTZ,
        'CRÍTICO: Nenhum administrador encontrado no sistema'::TEXT;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CRIAR FUNÇÃO DE SINCRONIZAÇÃO
-- Primeiro, remover a função existente se ela existir
DROP FUNCTION IF EXISTS public.sync_auth_and_profiles();

CREATE OR REPLACE FUNCTION public.sync_auth_and_profiles()
RETURNS TABLE(
  action TEXT,
  user_id UUID,
  email VARCHAR(255),
  details TEXT
) AS $$
DECLARE
  auth_user RECORD;
  profile_user RECORD;
BEGIN
  -- Encontrar usuários em auth.users sem profile correspondente
  FOR auth_user IN 
    SELECT au.id, au.email, au.created_at
    FROM auth.users au
    LEFT JOIN public.profiles p ON au.id = p.id
    WHERE p.id IS NULL
  LOOP
    -- Criar profile para usuário auth órfão
    INSERT INTO public.profiles (id, name, email, role, created_at)
    VALUES (
      auth_user.id,
      COALESCE(auth_user.email, 'Usuário'),
      auth_user.email,
      'user',
      auth_user.created_at
    );
    
    RETURN QUERY SELECT 
      'created_profile'::TEXT,
      auth_user.id,
      auth_user.email,
      'Profile criado para usuário auth existente'::TEXT;
  END LOOP;
  
  -- Encontrar profiles sem usuário auth correspondente
  FOR profile_user IN
    SELECT p.id, p.email, p.name, p.role
    FROM public.profiles p
    LEFT JOIN auth.users au ON p.id = au.id
    WHERE au.id IS NULL
  LOOP
    RETURN QUERY SELECT 
      'orphaned_profile'::TEXT,
      profile_user.id,
      profile_user.email,
      format('Profile órfão encontrado: %s (%s)', profile_user.name, profile_user.role)::TEXT;
  END LOOP;
  
  -- Verificar inconsistências de email
  FOR auth_user IN
    SELECT au.id, au.email as auth_email, p.email as profile_email
    FROM auth.users au
    JOIN public.profiles p ON au.id = p.id
    WHERE au.email != p.email
  LOOP
    -- Atualizar email do profile para coincidir com auth
    UPDATE public.profiles 
    SET email = auth_user.auth_email, updated_at = now()
    WHERE id = auth_user.id;
    
    RETURN QUERY SELECT 
      'email_synced'::TEXT,
      auth_user.id,
      auth_user.auth_email,
      format('Email sincronizado: %s -> %s', auth_user.profile_email, auth_user.auth_email)::TEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CORRIGIR FUNÇÃO ensure_user_profile
CREATE OR REPLACE FUNCTION public.ensure_user_profile()
RETURNS TABLE(user_id UUID, user_email TEXT, user_name TEXT, user_role TEXT) AS $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
  profile_exists BOOLEAN;
  admin_count INTEGER;
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
    -- Check if there are any existing admins
    SELECT COUNT(*) INTO admin_count
    FROM public.profiles
    WHERE role = 'admin';
    
    -- Only create admin if no admins exist, otherwise create regular user
    INSERT INTO public.profiles (id, name, email, role)
    VALUES (
      current_user_id,
      COALESCE(current_user_email, 'Usuário'),
      current_user_email,
      CASE 
        WHEN admin_count = 0 THEN 'admin'  -- First user becomes admin
        ELSE 'user'                        -- Subsequent users are regular users
      END
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

-- 4. CONCEDER PERMISSÕES
GRANT EXECUTE ON FUNCTION public.audit_admin_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sync_auth_and_profiles() TO authenticated;

-- ========================================
-- COMANDOS PARA EXECUTAR APÓS CRIAR AS FUNÇÕES:
-- ========================================

-- Executar auditoria de administradores:
-- SELECT * FROM public.audit_admin_users();

-- Executar sincronização:
-- SELECT * FROM public.sync_auth_and_profiles();

-- Verificar usuários duplicados:
-- SELECT email, COUNT(*) as count 
-- FROM public.profiles 
-- GROUP BY email 
-- HAVING COUNT(*) > 1;

-- Listar todos os administradores:
-- SELECT id, name, email, role, created_at 
-- FROM public.profiles 
-- WHERE role = 'admin' 
-- ORDER BY created_at;