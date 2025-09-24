-- ========================================
-- CRIAR ESTRUTURA COMPLETA NO SUPABASE
-- ========================================
-- Execute este script COMPLETO no Supabase Dashboard
-- Vá para: https://supabase.com/dashboard/project/[SEU_PROJECT_ID]/sql

-- ========================================
-- PASSO 1: CRIAR EXTENSÕES NECESSÁRIAS
-- ========================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- PASSO 2: CRIAR TABELA PROFILES (USUÁRIOS)
-- ========================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    password_hash TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- PASSO 3: CRIAR TABELA DE AUDITORIA
-- ========================================
CREATE TABLE IF NOT EXISTS public.user_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    action TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    performed_by UUID,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Adicionar constraints com CASCADE
ALTER TABLE public.user_audit_log 
DROP CONSTRAINT IF EXISTS user_audit_log_user_id_fkey;

ALTER TABLE public.user_audit_log 
ADD CONSTRAINT user_audit_log_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

ALTER TABLE public.user_audit_log 
DROP CONSTRAINT IF EXISTS user_audit_log_performed_by_fkey;

ALTER TABLE public.user_audit_log 
ADD CONSTRAINT user_audit_log_performed_by_fkey 
FOREIGN KEY (performed_by) 
REFERENCES public.profiles(id) 
ON DELETE SET NULL;

-- ========================================
-- PASSO 4: CRIAR FUNÇÕES DE HASH E VERIFICAÇÃO
-- ========================================

-- Função para hash de senha
CREATE OR REPLACE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN crypt(password, gen_salt('bf', 10));
END;
$$;

-- Função para verificar senha
CREATE OR REPLACE FUNCTION public.verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN crypt(password, hash) = hash;
END;
$$;

-- ========================================
-- PASSO 5: CRIAR FUNÇÃO DE AUTENTICAÇÃO
-- ========================================

CREATE OR REPLACE FUNCTION public.authenticate_user(
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
  -- Buscar usuário na tabela profiles
  SELECT id, name, email, role, password_hash, active
  INTO user_record
  FROM public.profiles
  WHERE email = user_email;
  
  -- Verificar se usuário existe
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, NULL::TEXT, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar se usuário está ativo
  IF NOT user_record.active THEN
    RETURN QUERY SELECT FALSE, user_record.id, user_record.name, user_record.role, 'Usuário inativo'::TEXT;
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

-- ========================================
-- PASSO 6: CRIAR FUNÇÃO DE CRIAÇÃO DE USUÁRIO
-- ========================================

CREATE OR REPLACE FUNCTION public.create_user_with_password(
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
  -- Verificar se email já existe
  IF EXISTS (SELECT 1 FROM public.profiles WHERE email = user_email) THEN
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
    active,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    user_name,
    user_email,
    user_role,
    public.hash_password(user_password),
    true,
    NOW(),
    NOW()
  );
  
  RETURN QUERY SELECT TRUE, new_user_id, 'Usuário criado com sucesso'::TEXT;
END;
$$;

-- ========================================
-- PASSO 7: CONFIGURAR PERMISSÕES
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

-- ========================================
-- PASSO 8: CONFIGURAR RLS (Row Level Security)
-- ========================================

-- Habilitar RLS nas tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_audit_log ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes
DROP POLICY IF EXISTS "Allow authenticated users to view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow admins full access" ON public.profiles;
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
-- PASSO 9: CRIAR USUÁRIOS DE TESTE
-- ========================================

-- Limpar usuários existentes (se houver)
DELETE FROM public.profiles WHERE email IN (
    'admin@hotel.com.br',
    'user@hotel.com.br', 
    'suporte@wfinformatica.com.br'
);

-- Criar usuários de teste
SELECT public.create_user_with_password('admin@hotel.com.br', 'Administrador', 'admin', 'admin123');
SELECT public.create_user_with_password('user@hotel.com.br', 'Usuário Teste', 'user', 'user123');
SELECT public.create_user_with_password('suporte@wfinformatica.com.br', 'Suporte WF', 'admin', 'suporte123');

-- ========================================
-- PASSO 10: VERIFICAÇÃO FINAL
-- ========================================

DO $$
DECLARE
  total_users INTEGER;
  users_with_password INTEGER;
  admin_exists BOOLEAN;
  functions_exist INTEGER;
BEGIN
  -- Contar usuários
  SELECT COUNT(*) INTO total_users FROM public.profiles;
  SELECT COUNT(*) INTO users_with_password FROM public.profiles WHERE password_hash IS NOT NULL;
  
  -- Verificar se admin existe
  admin_exists := EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE email = 'admin@hotel.com.br' AND password_hash IS NOT NULL
  );
  
  -- Verificar se funções existem
  SELECT COUNT(*) INTO functions_exist 
  FROM information_schema.routines 
  WHERE routine_schema = 'public' 
  AND routine_name = 'authenticate_user';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'ESTRUTURA CRIADA COM SUCESSO!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de usuários: %', total_users;
  RAISE NOTICE 'Usuários com senha: %', users_with_password;
  RAISE NOTICE 'Admin existe: %', admin_exists;
  RAISE NOTICE 'Função authenticate_user existe: %', (functions_exist > 0);
  RAISE NOTICE '';
  RAISE NOTICE 'CREDENCIAIS PARA TESTE:';
  RAISE NOTICE '- admin@hotel.com.br / admin123';
  RAISE NOTICE '- user@hotel.com.br / user123';
  RAISE NOTICE '- suporte@wfinformatica.com.br / suporte123';
  RAISE NOTICE '';
  RAISE NOTICE 'Agora você pode testar o login na aplicação!';
  RAISE NOTICE 'URL: http://localhost:8181';
END $$;