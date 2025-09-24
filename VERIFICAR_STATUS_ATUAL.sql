-- ========================================
-- VERIFICAÇÃO DO STATUS ATUAL DO SISTEMA
-- ========================================
-- Execute este script no Supabase Dashboard para verificar o que está impedindo o login

-- ========================================
-- PASSO 1: VERIFICAR USUÁRIOS EM AUTH.USERS
-- ========================================

SELECT 
  'AUTH_USERS' as tabela,
  id,
  email,
  email_confirmed_at IS NOT NULL as email_confirmado,
  created_at,
  updated_at
FROM auth.users
ORDER BY created_at DESC;

-- ========================================
-- PASSO 2: VERIFICAR USUÁRIOS EM PROFILES
-- ========================================

SELECT 
  'PROFILES' as tabela,
  id,
  name,
  email,
  role,
  password_hash IS NOT NULL as tem_senha_hash,
  LENGTH(password_hash) as tamanho_hash,
  created_at,
  updated_at
FROM public.profiles
ORDER BY created_at DESC;

-- ========================================
-- PASSO 3: VERIFICAR CORRESPONDÊNCIA ENTRE TABELAS
-- ========================================

SELECT 
  'CORRESPONDENCIA' as status,
  COALESCE(au.email, p.email) as email,
  au.id as auth_id,
  p.id as profile_id,
  au.id IS NOT NULL as existe_em_auth,
  p.id IS NOT NULL as existe_em_profiles,
  p.password_hash IS NOT NULL as tem_senha_hash,
  au.email_confirmed_at IS NOT NULL as email_confirmado
FROM auth.users au
FULL OUTER JOIN public.profiles p ON au.id = p.id
ORDER BY COALESCE(au.created_at, p.created_at) DESC;

-- ========================================
-- PASSO 4: VERIFICAR FUNÇÕES EXISTENTES
-- ========================================

-- Verificar se as funções necessárias existem
SELECT 
  'FUNCOES_EXISTENTES' as categoria,
  routine_name as funcao,
  routine_type as tipo
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('authenticate_user', 'create_user_with_password', 'hash_password', 'verify_password')
ORDER BY routine_name;

-- ========================================
-- PASSO 5: TESTAR FUNÇÃO DE AUTENTICAÇÃO
-- ========================================

-- Testar se a função authenticate_user existe e funciona
DO $$
DECLARE
  test_result RECORD;
  user_email TEXT;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'TESTANDO FUNÇÃO DE AUTENTICAÇÃO';
  RAISE NOTICE '========================================';
  
  -- Verificar se a função existe
  IF EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'authenticate_user'
  ) THEN
    RAISE NOTICE '✅ Função authenticate_user existe';
    
    -- Testar com usuários conhecidos
    FOR user_email IN 
      SELECT DISTINCT email FROM public.profiles 
      WHERE password_hash IS NOT NULL 
      LIMIT 3
    LOOP
      RAISE NOTICE 'Testando usuário: %', user_email;
      
      -- Testar senhas comuns
      BEGIN
        SELECT * INTO test_result FROM public.authenticate_user(user_email, '123456');
        IF test_result.success THEN
          RAISE NOTICE '  ✅ Login OK com senha: 123456';
        ELSE
          SELECT * INTO test_result FROM public.authenticate_user(user_email, 'admin123');
          IF test_result.success THEN
            RAISE NOTICE '  ✅ Login OK com senha: admin123';
          ELSE
            RAISE NOTICE '  ❌ Senhas testadas não funcionaram';
          END IF;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  ❌ Erro ao testar autenticação: %', SQLERRM;
      END;
    END LOOP;
  ELSE
    RAISE NOTICE '❌ Função authenticate_user NÃO existe';
  END IF;
END $$;

-- ========================================
-- PASSO 6: VERIFICAR POLÍTICAS RLS
-- ========================================

-- Verificar políticas da tabela profiles
SELECT 
  'POLITICAS_RLS' as categoria,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles';

-- ========================================
-- PASSO 7: VERIFICAR PERMISSÕES
-- ========================================

-- Verificar permissões nas funções
SELECT 
  'PERMISSOES_FUNCOES' as categoria,
  routine_name as funcao,
  routine_schema as schema,
  security_type as tipo_seguranca
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('authenticate_user', 'create_user_with_password', 'hash_password', 'verify_password');

-- ========================================
-- PASSO 8: DIAGNÓSTICO FINAL
-- ========================================

DO $$
DECLARE
  auth_count INTEGER;
  profile_count INTEGER;
  function_count INTEGER;
  hash_function_exists BOOLEAN;
BEGIN
  SELECT COUNT(*) INTO auth_count FROM auth.users;
  SELECT COUNT(*) INTO profile_count FROM public.profiles;
  SELECT COUNT(*) INTO function_count FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_name = 'authenticate_user';
  
  hash_function_exists := EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_name = 'hash_password'
  );
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'DIAGNÓSTICO FINAL';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Usuários em auth.users: %', auth_count;
  RAISE NOTICE 'Usuários em profiles: %', profile_count;
  RAISE NOTICE 'Função authenticate_user existe: %', function_count > 0;
  RAISE NOTICE 'Função hash_password existe: %', hash_function_exists;
  
  IF auth_count = 0 THEN
    RAISE NOTICE '⚠️  PROBLEMA: Nenhum usuário em auth.users';
  END IF;
  
  IF profile_count = 0 THEN
    RAISE NOTICE '⚠️  PROBLEMA: Nenhum usuário em profiles';
  END IF;
  
  IF function_count = 0 THEN
    RAISE NOTICE '⚠️  PROBLEMA: Função authenticate_user não existe';
  END IF;
  
  IF NOT hash_function_exists THEN
    RAISE NOTICE '⚠️  PROBLEMA: Função hash_password não existe';
  END IF;
END $$;