-- ========================================
-- CORRIGIR PGCRYPTO E FUNÇÕES DE AUTENTICAÇÃO (IDEMPOTENTE)
-- ========================================
-- Execute este arquivo no SQL Editor do Supabase (copie tudo e rode de uma vez)
-- Este script NÃO depende do esquema "pgcrypto" existir. As funções usam crypt/gen_salt sem prefixo
-- e fixam o search_path para public, evitando erros de esquema.

-- 1) Garantir extensão pgcrypto instalada (preferencialmente no schema extensions)
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- (Opcional) Conferir onde a extensão está instalada
-- SELECT e.extname, n.nspname AS schema
-- FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
-- WHERE e.extname = 'pgcrypto';

-- 2) Garantir coluna de senha
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- 3) Funções de senha (sem usar prefixo de esquema, com search_path fixo)
-- Wrappers compatíveis para localizar gen_salt/crypt no schema correto
DO $$
BEGIN
  -- Tentar localizar funções base em schemas comuns, incluindo pg_catalog
  IF to_regproc('extensions.gen_salt(text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._gen_salt_bf() RETURNS text AS $f$ SELECT extensions.gen_salt(''bf'') $f$ LANGUAGE sql VOLATILE;';
  ELSIF to_regproc('public.gen_salt(text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._gen_salt_bf() RETURNS text AS $f$ SELECT public.gen_salt(''bf'') $f$ LANGUAGE sql VOLATILE;';
  ELSIF to_regproc('pgcrypto.gen_salt(text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._gen_salt_bf() RETURNS text AS $f$ SELECT pgcrypto.gen_salt(''bf'') $f$ LANGUAGE sql VOLATILE;';
  ELSIF to_regproc('pg_catalog.gen_salt(text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._gen_salt_bf() RETURNS text AS $f$ SELECT pg_catalog.gen_salt(''bf'') $f$ LANGUAGE sql VOLATILE;';
  ELSE
    -- Criar stub que erra somente em tempo de execução
    EXECUTE $f$ CREATE OR REPLACE FUNCTION public._gen_salt_bf() RETURNS text
                 LANGUAGE plpgsql VOLATILE AS $body$
                 BEGIN
                   RAISE EXCEPTION 'gen_salt(text) não disponível; habilite a extensão pgcrypto';
                 END; $body$ $f$;
    RAISE NOTICE 'Função gen_salt(text) não encontrada (extensions/public/pgcrypto/pg_catalog) — wrapper de erro criado';
  END IF;

  -- Wrapper para crypt(text, text)
  IF to_regproc('extensions.crypt(text,text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._crypt(text, text) RETURNS text AS $f$ SELECT extensions.crypt($1, $2) $f$ LANGUAGE sql STABLE;';
  ELSIF to_regproc('public.crypt(text,text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._crypt(text, text) RETURNS text AS $f$ SELECT public.crypt($1, $2) $f$ LANGUAGE sql STABLE;';
  ELSIF to_regproc('pgcrypto.crypt(text,text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._crypt(text, text) RETURNS text AS $f$ SELECT pgcrypto.crypt($1, $2) $f$ LANGUAGE sql STABLE;';
  ELSIF to_regproc('pg_catalog.crypt(text,text)') IS NOT NULL THEN
    EXECUTE 'CREATE OR REPLACE FUNCTION public._crypt(text, text) RETURNS text AS $f$ SELECT pg_catalog.crypt($1, $2) $f$ LANGUAGE sql STABLE;';
  ELSE
    EXECUTE $f$ CREATE OR REPLACE FUNCTION public._crypt(text, text) RETURNS text
                 LANGUAGE plpgsql STABLE AS $body$
                 BEGIN
                   RAISE EXCEPTION 'crypt(text,text) não disponível; habilite a extensão pgcrypto';
                 END; $body$ $f$;
    RAISE NOTICE 'Função crypt(text,text) não encontrada (extensions/public/pgcrypto/pg_catalog) — wrapper de erro criado';
  END IF;
END
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pgcrypto, extensions
AS $$
BEGIN
  IF password IS NULL OR LENGTH(password) < 3 THEN
    RAISE EXCEPTION 'Senha deve ter pelo menos 3 caracteres';
  END IF;
  RETURN public._crypt(password, public._gen_salt_bf());
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pgcrypto, extensions
AS $$
BEGIN
  IF password IS NULL OR hash IS NULL THEN
    RETURN FALSE;
  END IF;
  RETURN public._crypt(password, hash) = hash;
END;
$$;

-- 4) Função de autenticação (comparação de e-mail normalizada)
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
SET search_path = public, pgcrypto, extensions
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

  -- Buscar usuário na tabela profiles (normalizado)
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

-- 5) Permissões mínimas para login e uso autenticado
GRANT USAGE ON SCHEMA public TO anon;
GRANT EXECUTE ON FUNCTION public.hash_password(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_password(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.authenticate_user(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public._gen_salt_bf() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public._crypt(text, text) TO anon, authenticated;

-- 6) Criar/atualizar um usuário admin para teste (edite e-mail/senha se quiser)
DO $$
DECLARE
  v_email TEXT := LOWER(TRIM('admin@hotel.com.br'));
  v_pass  TEXT := 'admin123';
  v_id    UUID;
BEGIN
  -- Garantir resolução de funções de extensão em tempo de execução
  PERFORM set_config('search_path', 'public,extensions,pgcrypto', true);

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE LOWER(TRIM(email)) = v_email
  ) THEN
    v_id := gen_random_uuid();
    INSERT INTO public.profiles (id, name, email, role, password_hash, created_at, updated_at)
    VALUES (v_id, 'Administrador do Sistema', v_email, 'admin', public.hash_password(v_pass), NOW(), NOW());
  ELSE
    UPDATE public.profiles
    SET password_hash = public.hash_password(v_pass),
        role = COALESCE(role, 'admin'),
        name = COALESCE(name, 'Administrador do Sistema'),
        updated_at = NOW()
    WHERE LOWER(TRIM(email)) = v_email;
  END IF;
END
$$ LANGUAGE plpgsql;

-- 7) Teste rápido
SELECT * FROM public.authenticate_user('admin@hotel.com.br', 'admin123');

-- 8) Dica: conferir extensão instalada
-- SELECT e.extname, n.nspname AS schema
-- FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
-- WHERE e.extname = 'pgcrypto';