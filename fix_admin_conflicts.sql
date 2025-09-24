-- SOLUÇÕES PARA CONFLITOS DE PERMISSÕES E DUPLICAÇÃO DE CONTAS ADMINISTRATIVAS
-- Execute este script no Supabase SQL Editor para resolver os problemas identificados

-- ========================================
-- PROBLEMA 1: FUNÇÃO ensure_user_profile CRIA ADMINISTRADORES AUTOMATICAMENTE
-- ========================================

-- A função ensure_user_profile está configurada para criar automaticamente
-- usuários com role 'admin', o que pode causar múltiplos administradores

-- SOLUÇÃO: Modificar a função para criar usuários com role 'user' por padrão
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

-- ========================================
-- PROBLEMA 2: SISTEMA DE AUTENTICAÇÃO HÍBRIDO
-- ========================================

-- O sistema usa tanto Supabase Auth quanto autenticação customizada
-- Isso pode causar inconsistências entre auth.users e profiles

-- SOLUÇÃO: Função para sincronizar dados entre auth.users e profiles
CREATE OR REPLACE FUNCTION public.sync_auth_and_profiles()
RETURNS TABLE(
  action TEXT,
  user_id UUID,
  email TEXT,
  details TEXT
) AS $$
DECLARE
  auth_user RECORD;
  profile_user RECORD;
BEGIN
  -- 1. Encontrar usuários em auth.users sem profile correspondente
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
      'user',  -- Sempre criar como usuário regular
      auth_user.created_at
    );
    
    RETURN QUERY SELECT 
      'created_profile'::TEXT,
      auth_user.id,
      auth_user.email,
      'Profile criado para usuário auth existente'::TEXT;
  END LOOP;
  
  -- 2. Encontrar profiles sem usuário auth correspondente
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
  
  -- 3. Verificar inconsistências de email
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

-- ========================================
-- PROBLEMA 3: MÚLTIPLOS ADMINISTRADORES
-- ========================================

-- SOLUÇÃO: Função para auditar e corrigir múltiplos administradores
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

-- ========================================
-- PROBLEMA 4: POLÍTICAS RLS INCONSISTENTES
-- ========================================

-- SOLUÇÃO: Recriar políticas RLS de forma consistente
DROP POLICY IF EXISTS "Allow profile reads for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile inserts for RPC functions" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile updates for admins" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile deletes for admins" ON public.profiles;

-- Política de leitura: usuários autenticados podem ler profiles
CREATE POLICY "authenticated_users_can_read_profiles" 
ON public.profiles 
FOR SELECT 
USING (auth.role() = 'authenticated');

-- Política de inserção: apenas funções RPC podem inserir
CREATE POLICY "rpc_functions_can_insert_profiles" 
ON public.profiles 
FOR INSERT 
WITH CHECK (true);  -- Controlado pelas funções RPC

-- Política de atualização: admins podem atualizar qualquer profile, usuários podem atualizar o próprio
CREATE POLICY "users_can_update_profiles" 
ON public.profiles 
FOR UPDATE 
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin' OR 
  id = auth.uid()
);

-- Política de exclusão: apenas admins podem excluir profiles
CREATE POLICY "admins_can_delete_profiles" 
ON public.profiles 
FOR DELETE 
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- ========================================
-- FUNÇÕES DE UTILIDADE PARA ADMINISTRAÇÃO
-- ========================================

-- Função para promover usuário a administrador (apenas se não houver admin)
CREATE OR REPLACE FUNCTION public.promote_to_admin(target_user_id UUID)
RETURNS TEXT AS $$
DECLARE
  current_user_role TEXT;
  admin_count INTEGER;
  target_user_name TEXT;
BEGIN
  -- Verificar se o usuário atual é admin
  SELECT role INTO current_user_role
  FROM public.profiles
  WHERE id = auth.uid();
  
  IF current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Apenas administradores podem promover usuários';
  END IF;
  
  -- Contar administradores existentes
  SELECT COUNT(*) INTO admin_count
  FROM public.profiles
  WHERE role = 'admin';
  
  -- Obter nome do usuário alvo
  SELECT name INTO target_user_name
  FROM public.profiles
  WHERE id = target_user_id;
  
  IF target_user_name IS NULL THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;
  
  -- Atualizar role para admin
  UPDATE public.profiles
  SET role = 'admin', updated_at = now()
  WHERE id = target_user_id;
  
  RETURN format('Usuário %s promovido a administrador. Total de admins: %s', 
                target_user_name, admin_count + 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para rebaixar administrador para usuário
CREATE OR REPLACE FUNCTION public.demote_from_admin(target_user_id UUID)
RETURNS TEXT AS $$
DECLARE
  current_user_role TEXT;
  admin_count INTEGER;
  target_user_name TEXT;
BEGIN
  -- Verificar se o usuário atual é admin
  SELECT role INTO current_user_role
  FROM public.profiles
  WHERE id = auth.uid();
  
  IF current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Apenas administradores podem rebaixar usuários';
  END IF;
  
  -- Verificar se não é o próprio usuário
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Você não pode rebaixar a si mesmo';
  END IF;
  
  -- Contar administradores
  SELECT COUNT(*) INTO admin_count
  FROM public.profiles
  WHERE role = 'admin';
  
  IF admin_count <= 1 THEN
    RAISE EXCEPTION 'Não é possível rebaixar o último administrador do sistema';
  END IF;
  
  -- Obter nome do usuário alvo
  SELECT name INTO target_user_name
  FROM public.profiles
  WHERE id = target_user_id;
  
  -- Atualizar role para user
  UPDATE public.profiles
  SET role = 'user', updated_at = now()
  WHERE id = target_user_id;
  
  RETURN format('Usuário %s rebaixado para usuário regular. Total de admins: %s', 
                target_user_name, admin_count - 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- GRANTS E PERMISSÕES
-- ========================================

GRANT EXECUTE ON FUNCTION public.sync_auth_and_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.audit_admin_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.promote_to_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.demote_from_admin(UUID) TO authenticated;

-- ========================================
-- INSTRUÇÕES DE USO
-- ========================================

-- Para executar as correções, execute as seguintes consultas:

-- 1. Sincronizar auth.users e profiles:
-- SELECT * FROM public.sync_auth_and_profiles();

-- 2. Auditar administradores:
-- SELECT * FROM public.audit_admin_users();

-- 3. Verificar usuários cadastrados:
-- SELECT id, name, email, role, created_at FROM public.profiles ORDER BY created_at;

-- 4. Promover usuário a admin (se necessário):
-- SELECT public.promote_to_admin('user-uuid-here');

-- 5. Rebaixar admin para user (se necessário):
-- SELECT public.demote_from_admin('user-uuid-here');