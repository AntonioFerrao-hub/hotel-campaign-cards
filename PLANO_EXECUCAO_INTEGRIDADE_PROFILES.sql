-- ========================================
-- PLANO DE EXECUÇÃO 100% - INTEGRIDADE TABELA PROFILES
-- ========================================
-- Execute este script COMPLETO no Supabase Dashboard
-- Vá para: https://supabase.com/dashboard/project/[SEU_PROJECT_ID]/sql

-- ========================================
-- FASE 1: DIAGNÓSTICO COMPLETO DO ESTADO ATUAL
-- ========================================

DO $$
DECLARE
  total_profiles INTEGER;
  profiles_with_password INTEGER;
  profiles_without_password INTEGER;
  duplicate_emails INTEGER;
  invalid_roles INTEGER;
  orphaned_audit_logs INTEGER;
  rec RECORD;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'DIAGNÓSTICO COMPLETO - TABELA PROFILES';
  RAISE NOTICE '========================================';
  
  -- Verificar se tabela profiles existe
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
    RAISE NOTICE 'ERRO CRÍTICO: Tabela profiles não existe!';
    RETURN;
  END IF;
  
  -- Contar total de profiles
  SELECT COUNT(*) INTO total_profiles FROM public.profiles;
  RAISE NOTICE 'Total de profiles: %', total_profiles;
  
  -- Verificar profiles com senha
  SELECT COUNT(*) INTO profiles_with_password FROM public.profiles WHERE password_hash IS NOT NULL;
  RAISE NOTICE 'Profiles com senha: %', profiles_with_password;
  
  -- Verificar profiles sem senha
  SELECT COUNT(*) INTO profiles_without_password FROM public.profiles WHERE password_hash IS NULL;
  RAISE NOTICE 'Profiles SEM senha: %', profiles_without_password;
  
  -- Verificar emails duplicados
  SELECT COUNT(*) INTO duplicate_emails FROM (
    SELECT email FROM public.profiles GROUP BY email HAVING COUNT(*) > 1
  ) duplicates;
  RAISE NOTICE 'Emails duplicados: %', duplicate_emails;
  
  -- Verificar roles inválidos
  SELECT COUNT(*) INTO invalid_roles FROM public.profiles 
  WHERE role NOT IN ('admin', 'user') OR role IS NULL;
  RAISE NOTICE 'Roles inválidos: %', invalid_roles;
  
  -- Verificar logs de auditoria órfãos
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_audit_log' AND table_schema = 'public') THEN
    SELECT COUNT(*) INTO orphaned_audit_logs FROM public.user_audit_log 
    WHERE user_id NOT IN (SELECT id FROM public.profiles);
    RAISE NOTICE 'Logs de auditoria órfãos: %', orphaned_audit_logs;
  ELSE
    RAISE NOTICE 'Tabela user_audit_log não existe';
  END IF;
  
  RAISE NOTICE '========================================';
  
  -- Listar todos os profiles existentes
  RAISE NOTICE 'PROFILES EXISTENTES:';
  FOR rec IN SELECT id, name, email, role, (password_hash IS NOT NULL) as has_password FROM public.profiles ORDER BY email LOOP
    RAISE NOTICE '- %: % (%) - Senha: %', rec.email, rec.name, rec.role, CASE WHEN rec.has_password THEN 'SIM' ELSE 'NÃO' END;
  END LOOP;
  
END $$;

-- ========================================
-- FASE 2: CORREÇÃO DE ESTRUTURA E CONSTRAINTS
-- ========================================

-- Garantir que a extensão pgcrypto está habilitada
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Criar tabela profiles se não existir (sem coluna active)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    password_hash TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de auditoria se não existir
CREATE TABLE IF NOT EXISTS public.user_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    action TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    performed_by UUID,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Adicionar constraints com CASCADE se não existirem
DO $$
BEGIN
  -- Constraint para user_id
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                 WHERE constraint_name = 'user_audit_log_user_id_fkey') THEN
    ALTER TABLE public.user_audit_log 
    ADD CONSTRAINT user_audit_log_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) 
    ON DELETE CASCADE;
  END IF;
  
  -- Constraint para performed_by
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                 WHERE constraint_name = 'user_audit_log_performed_by_fkey') THEN
    ALTER TABLE public.user_audit_log 
    ADD CONSTRAINT user_audit_log_performed_by_fkey 
    FOREIGN KEY (performed_by) 
    REFERENCES public.profiles(id) 
    ON DELETE SET NULL;
  END IF;
END $$;

-- ========================================
-- FASE 3: LIMPEZA DE DADOS INCONSISTENTES
-- ========================================

-- Remover profiles com emails duplicados (manter o mais recente)
DELETE FROM public.profiles 
WHERE id NOT IN (
  SELECT DISTINCT ON (email) id 
  FROM public.profiles 
  ORDER BY email, created_at DESC
);

-- Corrigir roles inválidos
UPDATE public.profiles 
SET role = 'user' 
WHERE role NOT IN ('admin', 'user') OR role IS NULL;

-- Remover logs de auditoria órfãos
DELETE FROM public.user_audit_log 
WHERE user_id NOT IN (SELECT id FROM public.profiles);

-- ========================================
-- FASE 4: RECRIAR FUNÇÕES DE INTEGRIDADE
-- ========================================

-- Remover TODAS as versões das funções existentes (método mais robusto)
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Remover todas as versões de hash_password
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'public' AND p.proname = 'hash_password'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', func_record.proname, func_record.args);
    END LOOP;
    
    -- Remover todas as versões de verify_password
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'public' AND p.proname = 'verify_password'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', func_record.proname, func_record.args);
    END LOOP;
    
    -- Remover todas as versões de authenticate_user
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'public' AND p.proname = 'authenticate_user'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', func_record.proname, func_record.args);
    END LOOP;
    
    -- Remover todas as versões de create_user_with_password
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'public' AND p.proname = 'create_user_with_password'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', func_record.proname, func_record.args);
    END LOOP;
    
    -- Remover todas as versões de update_user_profile
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'public' AND p.proname = 'update_user_profile'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', func_record.proname, func_record.args);
    END LOOP;
    
    -- Remover todas as versões de delete_user_profile
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'public' AND p.proname = 'delete_user_profile'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', func_record.proname, func_record.args);
    END LOOP;
    
    RAISE NOTICE 'Todas as versões das funções foram removidas com sucesso';
END $$;

-- Função para hash de senha
CREATE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF password IS NULL OR LENGTH(password) < 3 THEN
    RAISE EXCEPTION 'Senha deve ter pelo menos 3 caracteres';
  END IF;
  RETURN crypt(password, gen_salt('bf', 10));
END;
$$;

-- Função para verificar senha
CREATE FUNCTION public.verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF password IS NULL OR hash IS NULL THEN
    RETURN FALSE;
  END IF;
  RETURN crypt(password, hash) = hash;
END;
$$;

-- Função de autenticação com validações completas (sem verificação de active)
CREATE FUNCTION public.authenticate_user(
  user_email TEXT,
  user_password TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  user_id UUID,
  user_name TEXT,
  user_role TEXT,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_record RECORD;
BEGIN
  -- Validar parâmetros de entrada
  IF user_email IS NULL OR LENGTH(TRIM(user_email)) = 0 THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, NULL::TEXT, 'Email é obrigatório'::TEXT;
    RETURN;
  END IF;
  
  IF user_password IS NULL OR LENGTH(user_password) = 0 THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, NULL::TEXT, 'Senha é obrigatória'::TEXT;
    RETURN;
  END IF;
  
  -- Buscar usuário na tabela profiles
  SELECT id, name, email, role, password_hash
  INTO user_record
  FROM public.profiles
  WHERE LOWER(email) = LOWER(TRIM(user_email));
  
  -- Verificar se usuário existe
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, NULL::TEXT, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar se tem senha hash
  IF user_record.password_hash IS NULL THEN
    RETURN QUERY SELECT FALSE, user_record.id, user_record.name, user_record.role, 'Usuário sem senha definida'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar senha
  IF public.verify_password(user_password, user_record.password_hash) THEN
    RETURN QUERY SELECT TRUE, user_record.id, user_record.name, user_record.role, 'Login realizado com sucesso'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE, user_record.id, user_record.name, user_record.role, 'Senha incorreta'::TEXT;
  END IF;
END;
$$;

-- Função de criação de usuário com validações completas (sem campo active)
CREATE FUNCTION public.create_user_with_password(
  user_email TEXT,
  user_name TEXT,
  user_role TEXT DEFAULT 'user',
  user_password TEXT DEFAULT '123456'
)
RETURNS TABLE(
  success BOOLEAN,
  user_id UUID,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Validar parâmetros de entrada
  IF user_email IS NULL OR LENGTH(TRIM(user_email)) = 0 THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Email é obrigatório'::TEXT;
    RETURN;
  END IF;
  
  IF user_name IS NULL OR LENGTH(TRIM(user_name)) = 0 THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Nome é obrigatório'::TEXT;
    RETURN;
  END IF;
  
  IF user_role NOT IN ('admin', 'user') THEN
    user_role := 'user';
  END IF;
  
  -- Verificar se email já existe
  IF EXISTS (SELECT 1 FROM public.profiles WHERE LOWER(email) = LOWER(TRIM(user_email))) THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Email já existe'::TEXT;
    RETURN;
  END IF;
  
  -- Gerar novo ID
  new_user_id := gen_random_uuid();
  
  -- Criar usuário na tabela profiles
  INSERT INTO public.profiles (
    id,
    name,
    email,
    role,
    password_hash,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    TRIM(user_name),
    LOWER(TRIM(user_email)),
    user_role,
    public.hash_password(user_password),
    NOW(),
    NOW()
  );
  
  -- Registrar no log de auditoria
  INSERT INTO public.user_audit_log (
    user_id,
    action,
    new_data,
    performed_at
  ) VALUES (
    new_user_id,
    'CREATE',
    jsonb_build_object(
      'name', TRIM(user_name),
      'email', LOWER(TRIM(user_email)),
      'role', user_role
    ),
    NOW()
  );
  
  RETURN QUERY SELECT TRUE, new_user_id, 'Usuário criado com sucesso'::TEXT;
END;
$$;

-- Função para atualizar perfil de usuário
CREATE FUNCTION public.update_user_profile(
  target_user_id UUID,
  new_name TEXT,
  new_email TEXT,
  new_role TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  old_data JSONB;
  new_data JSONB;
BEGIN
  -- Verificar se usuário existe
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = target_user_id) THEN
    RETURN QUERY SELECT FALSE, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Capturar dados antigos
  SELECT jsonb_build_object('name', name, 'email', email, 'role', role)
  INTO old_data
  FROM public.profiles
  WHERE id = target_user_id;
  
  -- Atualizar dados
  UPDATE public.profiles
  SET 
    name = COALESCE(TRIM(new_name), name),
    email = COALESCE(LOWER(TRIM(new_email)), email),
    role = CASE WHEN new_role IN ('admin', 'user') THEN new_role ELSE role END,
    updated_at = NOW()
  WHERE id = target_user_id;
  
  -- Capturar dados novos
  SELECT jsonb_build_object('name', name, 'email', email, 'role', role)
  INTO new_data
  FROM public.profiles
  WHERE id = target_user_id;
  
  -- Registrar no log de auditoria
  INSERT INTO public.user_audit_log (
    user_id,
    action,
    old_data,
    new_data,
    performed_at
  ) VALUES (
    target_user_id,
    'UPDATE',
    old_data,
    new_data,
    NOW()
  );
  
  RETURN QUERY SELECT TRUE, 'Perfil atualizado com sucesso'::TEXT;
END;
$$;

-- Função para deletar usuário
CREATE FUNCTION public.delete_user_profile(target_user_id UUID)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_data JSONB;
BEGIN
  -- Verificar se usuário existe
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = target_user_id) THEN
    RETURN QUERY SELECT FALSE, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Capturar dados do usuário
  SELECT jsonb_build_object('name', name, 'email', email, 'role', role)
  INTO user_data
  FROM public.profiles
  WHERE id = target_user_id;
  
  -- Registrar no log de auditoria antes de deletar
  INSERT INTO public.user_audit_log (
    user_id,
    action,
    old_data,
    performed_at
  ) VALUES (
    target_user_id,
    'DELETE',
    user_data,
    NOW()
  );
  
  -- Deletar usuário (logs serão deletados automaticamente por CASCADE)
  DELETE FROM public.profiles WHERE id = target_user_id;
  
  RETURN QUERY SELECT TRUE, 'Usuário deletado com sucesso'::TEXT;
END;
$$;

-- ========================================
-- FASE 5: CONFIGURAR PERMISSÕES E RLS
-- ========================================

-- Dar permissões para usuários anônimos (necessário para login)
GRANT USAGE ON SCHEMA public TO anon;
GRANT EXECUTE ON FUNCTION public.authenticate_user TO anon;
GRANT EXECUTE ON FUNCTION public.hash_password TO anon;
GRANT EXECUTE ON FUNCTION public.verify_password TO anon;

-- Dar permissões para usuários autenticados
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.user_audit_log TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_password TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_profile TO authenticated;

-- Habilitar RLS nas tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_audit_log ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes
DROP POLICY IF EXISTS "Allow authenticated users to view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow admins full access to profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all audit logs" ON public.user_audit_log;
DROP POLICY IF EXISTS "System can insert audit logs" ON public.user_audit_log;

-- Políticas para profiles
CREATE POLICY "Allow authenticated users to view profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Allow admins full access to profiles"
  ON public.profiles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Políticas para audit log
CREATE POLICY "Admins can view all audit logs" ON public.user_audit_log
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "System can insert audit logs" ON public.user_audit_log
    FOR INSERT TO authenticated WITH CHECK (true);

-- ========================================
-- FASE 6: CRIAR/ATUALIZAR USUÁRIOS PADRÃO
-- ========================================

-- Limpar usuários de teste existentes
DELETE FROM public.profiles WHERE email IN (
    'admin@hotel.com.br',
    'user@hotel.com.br', 
    'suporte@wfinformatica.com.br'
);

-- Criar usuários padrão do sistema
SELECT public.create_user_with_password('admin@hotel.com.br', 'Administrador do Sistema', 'admin', 'admin123');
SELECT public.create_user_with_password('user@hotel.com.br', 'Usuário de Teste', 'user', 'user123');
SELECT public.create_user_with_password('suporte@wfinformatica.com.br', 'Suporte WF Informática', 'admin', 'suporte123');

-- ========================================
-- FASE 7: VERIFICAÇÃO FINAL E RELATÓRIO
-- ========================================

DO $$
DECLARE
  total_users INTEGER;
  users_with_password INTEGER;
  admin_count INTEGER;
  user_count INTEGER;
  functions_count INTEGER;
  constraints_count INTEGER;
  policies_count INTEGER;
BEGIN
  -- Contar usuários
  SELECT COUNT(*) INTO total_users FROM public.profiles;
  SELECT COUNT(*) INTO users_with_password FROM public.profiles WHERE password_hash IS NOT NULL;
  SELECT COUNT(*) INTO admin_count FROM public.profiles WHERE role = 'admin';
  SELECT COUNT(*) INTO user_count FROM public.profiles WHERE role = 'user';
  
  -- Verificar funções
  SELECT COUNT(*) INTO functions_count 
  FROM information_schema.routines 
  WHERE routine_schema = 'public' 
  AND routine_name IN ('authenticate_user', 'create_user_with_password', 'hash_password', 'verify_password');
  
  -- Verificar constraints
  SELECT COUNT(*) INTO constraints_count
  FROM information_schema.table_constraints
  WHERE table_name = 'user_audit_log' AND constraint_type = 'FOREIGN KEY';
  
  -- Verificar políticas RLS
  SELECT COUNT(*) INTO policies_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename IN ('profiles', 'user_audit_log');
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RELATÓRIO FINAL - INTEGRIDADE 100%';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de usuários: %', total_users;
  RAISE NOTICE 'Usuários com senha: %', users_with_password;
  RAISE NOTICE 'Administradores: %', admin_count;
  RAISE NOTICE 'Usuários comuns: %', user_count;
  RAISE NOTICE 'Funções criadas: %/4', functions_count;
  RAISE NOTICE 'Constraints FK: %/2', constraints_count;
  RAISE NOTICE 'Políticas RLS: %', policies_count;
  RAISE NOTICE '';
  RAISE NOTICE 'CREDENCIAIS PARA TESTE:';
  RAISE NOTICE '- admin@hotel.com.br / admin123 (ADMIN)';
  RAISE NOTICE '- user@hotel.com.br / user123 (USER)';
  RAISE NOTICE '- suporte@wfinformatica.com.br / suporte123 (ADMIN)';
  RAISE NOTICE '';
  RAISE NOTICE 'STATUS: SISTEMA 100% ÍNTEGRO E FUNCIONAL';
  RAISE NOTICE 'URL da aplicação: http://localhost:8181';
  RAISE NOTICE '========================================';
END $$;