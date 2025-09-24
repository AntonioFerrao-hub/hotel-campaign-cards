-- Script para aplicar (ou corrigir) as funções de autenticação no Supabase
-- Execute este script no SQL Editor do Supabase Dashboard
-- Observação: cole exatamente como está (sem aspas) e execute tudo de uma vez ou em blocos

-- 1) Extensão necessária (idempotente)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2) Garantir coluna de senha no perfil (idempotente)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- 3) Função para gerar hash de senha (uso de pgcrypto qualificado)
CREATE OR REPLACE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN pgcrypto.crypt(password, pgcrypto.gen_salt('bf'));
END;
$$;

-- 4) Função para verificar senha (uso de pgcrypto qualificado)
CREATE OR REPLACE FUNCTION public.verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (pgcrypto.crypt(password, hash) = hash);
END;
$$;

-- 5) Função principal de autenticação
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
SET search_path = public
AS $$
DECLARE
  profile_record public.profiles%ROWTYPE;
BEGIN
  -- Buscar usuário pelo email normalizado
  SELECT * INTO profile_record
  FROM public.profiles
  WHERE email = lower(trim(user_email));

  -- Usuário não encontrado
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, NULL::UUID, NULL::TEXT, NULL::TEXT, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;

  -- Senha não configurada
  IF profile_record.password_hash IS NULL THEN
    RETURN QUERY SELECT false, profile_record.id, profile_record.name, profile_record.role, 'Senha não configurada para este usuário'::TEXT;
    RETURN;
  END IF;

  -- Senha incorreta
  IF NOT public.verify_password(user_password, profile_record.password_hash) THEN
    RETURN QUERY SELECT false, profile_record.id, profile_record.name, profile_record.role, 'Senha incorreta'::TEXT;
    RETURN;
  END IF;

  -- Login OK
  RETURN QUERY SELECT true, profile_record.id, profile_record.name, profile_record.role, 'Login realizado com sucesso'::TEXT;
END;
$$;

-- 6) Permissões
GRANT EXECUTE ON FUNCTION public.hash_password(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.verify_password(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.authenticate_user(TEXT, TEXT) TO authenticated, anon;

-- Fim
-- Dica: após executar, você pode testar com SELECT public.authenticate_user('email@dominio.com', 'sua_senha');