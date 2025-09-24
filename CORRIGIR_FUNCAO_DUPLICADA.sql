-- ========================================
-- CORRIGIR FUNÇÃO DUPLICADA NO SUPABASE
-- ========================================
-- Execute este script no Supabase Dashboard para corrigir o erro de função duplicada
-- Vá para: https://supabase.com/dashboard/project/[SEU_PROJECT_ID]/sql

-- ========================================
-- PASSO 1: REMOVER FUNÇÕES EXISTENTES
-- ========================================

-- Remover todas as versões da função create_user_with_password
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_password(TEXT, TEXT, TEXT, TEXT);

-- Remover outras funções que podem estar duplicadas
DROP FUNCTION IF EXISTS public.authenticate_user(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.hash_password(TEXT);
DROP FUNCTION IF EXISTS public.verify_password(TEXT, TEXT);

-- ========================================
-- PASSO 2: RECRIAR FUNÇÕES CORRETAMENTE
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

-- Função de autenticação
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

-- Função de criação de usuário (SEM DUPLICATAS)
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
-- PASSO 3: CONFIGURAR PERMISSÕES
-- ========================================

-- Dar permissões para usuários anônimos (necessário para login)
GRANT USAGE ON SCHEMA public TO anon;
GRANT EXECUTE ON FUNCTION public.authenticate_user TO anon;
GRANT EXECUTE ON FUNCTION public.hash_password TO anon;
GRANT EXECUTE ON FUNCTION public.verify_password TO anon;

-- Dar permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION public.create_user_with_password TO authenticated;

-- ========================================
-- PASSO 4: RECRIAR USUÁRIOS DE TESTE
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
-- PASSO 5: VERIFICAÇÃO FINAL
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
  RAISE NOTICE 'CORREÇÃO APLICADA COM SUCESSO!';
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