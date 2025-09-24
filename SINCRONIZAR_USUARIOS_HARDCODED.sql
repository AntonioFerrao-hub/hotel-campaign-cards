-- ========================================
-- SINCRONIZAÇÃO DE USUÁRIOS HARDCODED
-- ========================================
-- Execute este script no Supabase Dashboard para sincronizar usuários hardcoded

-- PROBLEMA IDENTIFICADO:
-- - admin@hotel.com.br funciona mas não está na base de dados
-- - Usuários da base de dados não conseguem fazer login
-- - Inconsistência entre usuários hardcoded e base de dados

-- SOLUÇÃO:
-- 1. Inserir usuários hardcoded na base de dados
-- 2. Garantir que tenham senhas hash corretas
-- 3. Manter compatibilidade com sistema atual

-- ========================================
-- PASSO 1: VERIFICAR ESTADO ATUAL
-- ========================================

-- Verificar usuários existentes na base
SELECT 
  'USUARIOS_EXISTENTES' as status,
  id,
  name,
  email,
  role,
  password_hash IS NOT NULL as tem_senha,
  created_at
FROM public.profiles
ORDER BY created_at;

-- ========================================
-- PASSO 2: INSERIR/ATUALIZAR USUÁRIOS HARDCODED
-- ========================================

-- Função para inserir ou atualizar usuário hardcoded
CREATE OR REPLACE FUNCTION public.upsert_hardcoded_user(
  user_id TEXT,
  user_name TEXT,
  user_email TEXT,
  user_password TEXT,
  user_role TEXT
)
RETURNS TEXT AS $$
DECLARE
  target_uuid UUID;
  existing_user RECORD;
BEGIN
  -- Converter ID string para UUID (com padding se necessário)
  target_uuid := CASE 
    WHEN user_id = '1' THEN '00000000-0000-0000-0000-000000000001'::UUID
    WHEN user_id = '2' THEN '00000000-0000-0000-0000-000000000002'::UUID
    WHEN user_id = '3' THEN '00000000-0000-0000-0000-000000000003'::UUID
    ELSE user_id::UUID
  END;
  
  -- Verificar se usuário já existe
  SELECT * INTO existing_user
  FROM public.profiles
  WHERE id = target_uuid OR email = lower(trim(user_email));
  
  IF FOUND THEN
    -- Atualizar usuário existente
    UPDATE public.profiles
    SET 
      id = target_uuid,
      name = user_name,
      email = lower(trim(user_email)),
      role = user_role,
      password_hash = public.hash_password(user_password),
      updated_at = NOW()
    WHERE id = existing_user.id OR email = lower(trim(user_email));
    
    RETURN format('Usuário %s atualizado com ID %s', user_email, target_uuid);
  ELSE
    -- Inserir novo usuário
    INSERT INTO public.profiles (id, name, email, role, password_hash, created_at, updated_at)
    VALUES (
      target_uuid,
      user_name,
      lower(trim(user_email)),
      user_role,
      public.hash_password(user_password),
      NOW(),
      NOW()
    );
    
    RETURN format('Usuário %s criado com ID %s', user_email, target_uuid);
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN format('Erro ao processar usuário %s: %s', user_email, SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- PASSO 3: EXECUTAR SINCRONIZAÇÃO
-- ========================================

-- Sincronizar usuários hardcoded
SELECT public.upsert_hardcoded_user('1', 'Administrador', 'admin@hotel.com.br', 'admin123', 'admin');
SELECT public.upsert_hardcoded_user('2', 'Usuário Teste', 'user@hotel.com.br', 'user123', 'user');
SELECT public.upsert_hardcoded_user('3', 'Suporte WF', 'suporte@wfinformatica.com.br', '123456', 'admin');

-- ========================================
-- PASSO 3.1: CORRIGIR USUÁRIOS EXISTENTES SEM SENHA
-- ========================================

-- Atualizar usuários existentes que não têm senha hash
DO $$
DECLARE
  user_record RECORD;
  senha_padrao TEXT := '123456'; -- Senha padrão para usuários sem senha
BEGIN
  RAISE NOTICE 'Corrigindo usuários existentes sem senha...';
  
  FOR user_record IN 
    SELECT id, name, email, role
    FROM public.profiles
    WHERE password_hash IS NULL
      AND email NOT IN ('admin@hotel.com.br', 'user@hotel.com.br', 'suporte@wfinformatica.com.br')
  LOOP
    RAISE NOTICE 'Definindo senha padrão para: % (%)', user_record.name, user_record.email;
    
    UPDATE public.profiles
    SET 
      password_hash = public.hash_password(senha_padrao),
      updated_at = NOW()
    WHERE id = user_record.id;
  END LOOP;
  
  RAISE NOTICE 'Correção concluída. Senha padrão: %', senha_padrao;
END $$;

-- ========================================
-- PASSO 4: ATUALIZAR FUNÇÃO DE AUTENTICAÇÃO
-- ========================================

-- Função de autenticação melhorada que prioriza base de dados
CREATE OR REPLACE FUNCTION public.authenticate_user(
  user_email TEXT,
  user_password TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  user_id UUID,
  user_name TEXT,
  user_role TEXT,
  message TEXT,
  auth_type TEXT
) AS $$
DECLARE
  profile_record public.profiles%ROWTYPE;
  auth_user_id UUID;
BEGIN
  -- Normalizar email
  user_email := lower(trim(user_email));
  
  -- MÉTODO 1: Autenticação via profiles (PRIORIDADE)
  SELECT * INTO profile_record
  FROM public.profiles
  WHERE email = user_email;
  
  IF FOUND AND profile_record.password_hash IS NOT NULL THEN
    -- Verificar senha
    IF public.verify_password(user_password, profile_record.password_hash) THEN
      RETURN QUERY SELECT 
        true, 
        profile_record.id, 
        profile_record.name, 
        profile_record.role, 
        'Login realizado com sucesso'::TEXT,
        'database'::TEXT;
      RETURN;
    ELSE
      RETURN QUERY SELECT 
        false, 
        profile_record.id, 
        profile_record.name, 
        profile_record.role, 
        'Senha incorreta'::TEXT,
        'database'::TEXT;
      RETURN;
    END IF;
  END IF;
  
  -- MÉTODO 2: Verificar se existe em auth.users
  SELECT au.id INTO auth_user_id
  FROM auth.users au
  WHERE au.email = user_email;
  
  IF FOUND THEN
    -- Buscar profile correspondente
    SELECT * INTO profile_record
    FROM public.profiles
    WHERE id = auth_user_id;
    
    IF FOUND THEN
      RETURN QUERY SELECT 
        false, 
        profile_record.id, 
        profile_record.name, 
        profile_record.role, 
        'Use o sistema de autenticação do Supabase'::TEXT,
        'supabase'::TEXT;
      RETURN;
    END IF;
  END IF;
  
  -- MÉTODO 3: Fallback para usuários hardcoded (APENAS SE NÃO EXISTIR NA BASE)
  IF user_email = 'admin@hotel.com.br' AND user_password = 'admin123' THEN
    RETURN QUERY SELECT 
      true, 
      '00000000-0000-0000-0000-000000000001'::UUID, 
      'Administrador'::TEXT, 
      'admin'::TEXT, 
      'Login realizado (fallback hardcoded)'::TEXT,
      'hardcoded'::TEXT;
    RETURN;
  END IF;
  
  IF user_email = 'user@hotel.com.br' AND user_password = 'user123' THEN
    RETURN QUERY SELECT 
      true, 
      '00000000-0000-0000-0000-000000000002'::UUID, 
      'Usuário Teste'::TEXT, 
      'user'::TEXT, 
      'Login realizado (fallback hardcoded)'::TEXT,
      'hardcoded'::TEXT;
    RETURN;
  END IF;
  
  IF user_email = 'suporte@wfinformatica.com.br' AND user_password = '123456' THEN
    RETURN QUERY SELECT 
      true, 
      '00000000-0000-0000-0000-000000000003'::UUID, 
      'Suporte WF'::TEXT, 
      'admin'::TEXT, 
      'Login realizado (fallback hardcoded)'::TEXT,
      'hardcoded'::TEXT;
    RETURN;
  END IF;
  
  -- Falha na autenticação
  RETURN QUERY SELECT 
    false, 
    NULL::UUID, 
    NULL::TEXT, 
    NULL::TEXT, 
    'Email ou senha incorretos'::TEXT,
    'failed'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- PASSO 5: CONCEDER PERMISSÕES
-- ========================================

GRANT EXECUTE ON FUNCTION public.upsert_hardcoded_user(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.authenticate_user(TEXT, TEXT) TO authenticated, anon;

-- ========================================
-- PASSO 6: VERIFICAR RESULTADO
-- ========================================

-- Verificar usuários sincronizados
SELECT 
  'USUARIOS_SINCRONIZADOS' as status,
  id,
  name,
  email,
  role,
  password_hash IS NOT NULL as tem_senha,
  created_at,
  updated_at
FROM public.profiles
WHERE email IN ('admin@hotel.com.br', 'user@hotel.com.br', 'suporte@wfinformatica.com.br')
ORDER BY email;

-- Testar autenticação dos usuários hardcoded
SELECT 'TESTE_ADMIN' as teste, * FROM public.authenticate_user('admin@hotel.com.br', 'admin123');
SELECT 'TESTE_USER' as teste, * FROM public.authenticate_user('user@hotel.com.br', 'user123');
SELECT 'TESTE_SUPORTE' as teste, * FROM public.authenticate_user('suporte@wfinformatica.com.br', '123456');

-- ========================================
-- RESULTADO ESPERADO
-- ========================================

-- Após executar este script:
-- 1. Usuários hardcoded estarão na base de dados
-- 2. Terão senhas hash corretas
-- 3. Sistema priorizará autenticação via base de dados
-- 4. Fallback hardcoded ainda funcionará se necessário
-- 5. Todos os usuários poderão fazer login normalmente

SELECT 'SINCRONIZAÇÃO CONCLUÍDA COM SUCESSO!' as status;