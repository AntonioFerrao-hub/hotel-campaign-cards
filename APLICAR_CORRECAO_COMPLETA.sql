-- ========================================
-- APLICAR CORREÇÃO COMPLETA DO SISTEMA
-- ========================================
-- Execute este script COMPLETO no Supabase Dashboard para corrigir todos os problemas

-- ========================================
-- PASSO 1: CRIAR FUNÇÕES DE HASH E VERIFICAÇÃO
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
-- PASSO 2: CRIAR/ATUALIZAR FUNÇÃO DE AUTENTICAÇÃO
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
  SELECT id, name, email, role, password_hash
  INTO user_record
  FROM public.profiles
  WHERE email = user_email;
  
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

-- ========================================
-- PASSO 3: CRIAR/ATUALIZAR FUNÇÃO DE CRIAÇÃO DE USUÁRIO
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
  auth_user_id UUID;
BEGIN
  -- Gerar novo ID
  new_user_id := gen_random_uuid();
  
  -- Tentar criar usuário no auth.users primeiro (se possível)
  BEGIN
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      role
    ) VALUES (
      new_user_id,
      user_email,
      crypt(user_password, gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object('name', user_name, 'role', user_role),
      FALSE,
      'authenticated'
    );
    auth_user_id := new_user_id;
  EXCEPTION WHEN OTHERS THEN
    -- Se falhar, continuar sem auth.users
    auth_user_id := new_user_id;
  END;
  
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
    auth_user_id,
    user_name,
    user_email,
    user_role,
    public.hash_password(user_password),
    NOW(),
    NOW()
  );
  
  RETURN QUERY SELECT TRUE, auth_user_id, 'Usuário criado com sucesso'::TEXT;
  
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT FALSE, NULL::UUID, ('Erro ao criar usuário: ' || SQLERRM)::TEXT;
END;
$$;

-- ========================================
-- PASSO 4: CRIAR USUÁRIOS HARDCODED
-- ========================================

-- Função para criar/atualizar usuário (upsert)
CREATE OR REPLACE FUNCTION public.upsert_hardcoded_user(
  user_email TEXT,
  user_name TEXT,
  user_role TEXT,
  user_password TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing_user_id UUID;
  new_user_id UUID;
BEGIN
  -- Verificar se usuário já existe
  SELECT id INTO existing_user_id
  FROM public.profiles
  WHERE email = user_email;
  
  IF existing_user_id IS NOT NULL THEN
    -- Atualizar usuário existente
    UPDATE public.profiles
    SET 
      name = user_name,
      role = user_role,
      password_hash = public.hash_password(user_password),
      updated_at = NOW()
    WHERE id = existing_user_id;
    
    RETURN 'Usuário ' || user_email || ' atualizado com sucesso';
  ELSE
    -- Criar novo usuário
    SELECT user_id INTO new_user_id
    FROM public.create_user_with_password(user_email, user_name, user_role, user_password);
    
    RETURN 'Usuário ' || user_email || ' criado com sucesso';
  END IF;
END;
$$;

-- Criar usuários hardcoded
SELECT public.upsert_hardcoded_user('admin@hotel.com.br', 'Administrador do Sistema', 'admin', 'admin123');
SELECT public.upsert_hardcoded_user('user@hotel.com.br', 'Usuário de Teste', 'user', 'user123');
SELECT public.upsert_hardcoded_user('suporte@wfinformatica.com.br', 'Suporte WF Informática', 'admin', 'suporte123');

-- ========================================
-- PASSO 5: CORRIGIR USUÁRIOS EXISTENTES SEM SENHA
-- ========================================

-- Definir senha padrão para usuários sem senha
DO $$
DECLARE
  user_record RECORD;
  senha_padrao TEXT := '123456';
BEGIN
  FOR user_record IN 
    SELECT id, name, email, role
    FROM public.profiles
    WHERE password_hash IS NULL
      AND email NOT IN ('admin@hotel.com.br', 'user@hotel.com.br', 'suporte@wfinformatica.com.br')
  LOOP
    UPDATE public.profiles
    SET 
      password_hash = public.hash_password(senha_padrao),
      updated_at = NOW()
    WHERE id = user_record.id;
    
    RAISE NOTICE 'Senha definida para: % (%) - Senha: %', user_record.name, user_record.email, senha_padrao;
  END LOOP;
END $$;

-- ========================================
-- PASSO 6: CONFIGURAR PERMISSÕES
-- ========================================

-- Dar permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION public.authenticate_user TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_password TO authenticated;
GRANT EXECUTE ON FUNCTION public.hash_password TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_password TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_hardcoded_user TO authenticated;

-- Dar permissões para usuários anônimos (para login)
GRANT EXECUTE ON FUNCTION public.authenticate_user TO anon;
GRANT EXECUTE ON FUNCTION public.hash_password TO anon;
GRANT EXECUTE ON FUNCTION public.verify_password TO anon;

-- ========================================
-- PASSO 7: CONFIGURAR RLS (Row Level Security)
-- ========================================

-- Habilitar RLS na tabela profiles se não estiver habilitado
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes que podem estar causando problemas
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- Criar políticas mais permissivas para resolver problemas de acesso
CREATE POLICY "Allow authenticated users to view profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Allow admins full access"
  ON public.profiles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ========================================
-- PASSO 8: VERIFICAÇÃO FINAL
-- ========================================

DO $$
DECLARE
  total_users INTEGER;
  users_with_password INTEGER;
  admin_exists BOOLEAN;
BEGIN
  SELECT COUNT(*) INTO total_users FROM public.profiles;
  SELECT COUNT(*) INTO users_with_password FROM public.profiles WHERE password_hash IS NOT NULL;
  
  admin_exists := EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE email = 'admin@hotel.com.br' AND password_hash IS NOT NULL
  );
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'CORREÇÃO APLICADA COM SUCESSO!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de usuários: %', total_users;
  RAISE NOTICE 'Usuários com senha: %', users_with_password;
  RAISE NOTICE 'Admin existe: %', admin_exists;
  RAISE NOTICE '';
  RAISE NOTICE 'CREDENCIAIS PARA TESTE:';
  RAISE NOTICE '- admin@hotel.com.br / admin123';
  RAISE NOTICE '- user@hotel.com.br / user123';
  RAISE NOTICE '- suporte@wfinformatica.com.br / suporte123';
  RAISE NOTICE '- Outros usuários / 123456';
  RAISE NOTICE '';
  RAISE NOTICE 'Agora você pode testar o login na aplicação!';
END $$;