-- ========================================
-- HABILITAR PGCRYPTO E FUNÇÕES (VERSÃO SIMPLIFICADA)
-- ========================================
-- Execute este arquivo APÓS habilitar pgcrypto no Dashboard do Supabase

-- 1) Habilitar extensão pgcrypto (caso não tenha sido feito pelo Dashboard)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2) Garantir coluna de senha na tabela profiles
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- 3) Função para hash de senha
CREATE OR REPLACE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF password IS NULL OR LENGTH(password) < 3 THEN
    RAISE EXCEPTION 'Senha deve ter pelo menos 3 caracteres';
  END IF;
  RETURN crypt(password, gen_salt('bf'));
END;
$$;

-- 4) Função para verificar senha
CREATE OR REPLACE FUNCTION public.verify_password(password TEXT, hash TEXT)
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

-- 5) Função de autenticação
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
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(user_email));

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

-- 6) Permissões
GRANT EXECUTE ON FUNCTION public.hash_password(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_password(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.authenticate_user(TEXT, TEXT) TO anon;

-- 7) Criar usuário admin
DO $$
BEGIN
  -- Verificar se o usuário já existe
  IF EXISTS (SELECT 1 FROM public.profiles WHERE email = 'admin@hotel.com.br') THEN
    -- Atualizar usuário existente
    UPDATE public.profiles 
    SET 
      password_hash = public.hash_password('admin123'),
      role = 'admin',
      name = 'Administrador do Sistema',
      updated_at = NOW()
    WHERE email = 'admin@hotel.com.br';
  ELSE
    -- Criar novo usuário
    INSERT INTO public.profiles (id, name, email, role, password_hash, created_at, updated_at)
    VALUES (
      gen_random_uuid(),
      'Administrador do Sistema',
      'admin@hotel.com.br',
      'admin',
      public.hash_password('admin123'),
      NOW(),
      NOW()
    );
  END IF;
END $$;

-- 8) Teste
SELECT * FROM public.authenticate_user('admin@hotel.com.br', 'admin123');