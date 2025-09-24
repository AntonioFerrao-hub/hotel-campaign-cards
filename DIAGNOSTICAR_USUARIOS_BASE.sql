-- ========================================
-- DIAGNÓSTICO: USUÁRIOS DA BASE DE DADOS
-- ========================================
-- Execute este script no Supabase Dashboard para diagnosticar problemas de acesso

-- ========================================
-- PASSO 1: LISTAR TODOS OS USUÁRIOS
-- ========================================

-- Verificar todos os usuários na tabela profiles
SELECT 
  'TODOS_OS_USUARIOS' as categoria,
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
-- PASSO 2: VERIFICAR USUÁRIOS SEM SENHA
-- ========================================

-- Usuários que não têm senha hash (não podem fazer login)
SELECT 
  'USUARIOS_SEM_SENHA' as categoria,
  id,
  name,
  email,
  role,
  created_at
FROM public.profiles
WHERE password_hash IS NULL
ORDER BY created_at DESC;

-- ========================================
-- PASSO 3: TESTAR FUNÇÃO DE HASH
-- ========================================

-- Verificar se a função de hash está funcionando
SELECT 
  'TESTE_HASH' as teste,
  public.hash_password('123456') as hash_gerado,
  LENGTH(public.hash_password('123456')) as tamanho_hash;

-- Verificar se a função de verificação está funcionando
SELECT 
  'TESTE_VERIFICACAO' as teste,
  public.verify_password('123456', public.hash_password('123456')) as senha_correta,
  public.verify_password('senha_errada', public.hash_password('123456')) as senha_incorreta;

-- ========================================
-- PASSO 4: TESTAR AUTENTICAÇÃO DE USUÁRIOS EXISTENTES
-- ========================================

-- Testar autenticação para cada usuário na base
DO $$
DECLARE
  user_record RECORD;
  auth_result RECORD;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'TESTANDO AUTENTICAÇÃO DOS USUÁRIOS';
  RAISE NOTICE '========================================';
  
  FOR user_record IN 
    SELECT id, name, email, role, password_hash IS NOT NULL as tem_senha
    FROM public.profiles
    ORDER BY created_at
  LOOP
    RAISE NOTICE 'Usuário: % (%) - Tem senha: %', user_record.name, user_record.email, user_record.tem_senha;
    
    -- Se tem senha, tentar algumas senhas comuns
    IF user_record.tem_senha THEN
      -- Testar senhas comuns
      SELECT * INTO auth_result FROM public.authenticate_user(user_record.email, '123456');
      IF auth_result.success THEN
        RAISE NOTICE '  ✅ Login OK com senha: 123456';
      ELSE
        SELECT * INTO auth_result FROM public.authenticate_user(user_record.email, 'admin123');
        IF auth_result.success THEN
          RAISE NOTICE '  ✅ Login OK com senha: admin123';
        ELSE
          SELECT * INTO auth_result FROM public.authenticate_user(user_record.email, 'user123');
          IF auth_result.success THEN
            RAISE NOTICE '  ✅ Login OK com senha: user123';
          ELSE
            RAISE NOTICE '  ❌ Nenhuma senha comum funcionou';
          END IF;
        END IF;
      END IF;
    ELSE
      RAISE NOTICE '  ⚠️  Usuário sem senha hash - não pode fazer login';
    END IF;
  END LOOP;
END $$;

-- ========================================
-- PASSO 5: VERIFICAR CORRESPONDÊNCIA COM AUTH.USERS
-- ========================================

-- Verificar se usuários da base têm correspondência em auth.users
SELECT 
  'CORRESPONDENCIA_AUTH' as categoria,
  p.id,
  p.name,
  p.email,
  p.role,
  CASE 
    WHEN au.id IS NOT NULL THEN 'EXISTE_EM_AUTH'
    ELSE 'FALTA_EM_AUTH'
  END as status_auth,
  au.email_confirmed_at IS NOT NULL as email_confirmado
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
ORDER BY p.created_at DESC;

-- ========================================
-- PASSO 6: IDENTIFICAR PROBLEMAS ESPECÍFICOS
-- ========================================

-- Problema 1: Usuários com email duplicado
SELECT 
  'EMAILS_DUPLICADOS' as problema,
  email,
  COUNT(*) as quantidade,
  array_agg(id) as ids,
  array_agg(name) as nomes
FROM public.profiles
GROUP BY email
HAVING COUNT(*) > 1;

-- Problema 2: Usuários com IDs conflitantes
SELECT 
  'IDS_CONFLITANTES' as problema,
  p1.id,
  p1.email as email1,
  p1.name as nome1,
  p2.email as email2,
  p2.name as nome2
FROM public.profiles p1
JOIN public.profiles p2 ON p1.id = p2.id AND p1.email != p2.email;

-- Problema 3: Usuários sem role definido
SELECT 
  'USUARIOS_SEM_ROLE' as problema,
  id,
  name,
  email,
  role
FROM public.profiles
WHERE role IS NULL OR role = '';

-- ========================================
-- PASSO 7: RESUMO DO DIAGNÓSTICO
-- ========================================

SELECT 
  'RESUMO_DIAGNOSTICO' as status,
  (SELECT COUNT(*) FROM public.profiles) as total_usuarios,
  (SELECT COUNT(*) FROM public.profiles WHERE password_hash IS NOT NULL) as usuarios_com_senha,
  (SELECT COUNT(*) FROM public.profiles WHERE password_hash IS NULL) as usuarios_sem_senha,
  (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin') as admins,
  (SELECT COUNT(*) FROM public.profiles WHERE role = 'user') as users,
  (SELECT COUNT(*) FROM public.profiles WHERE role = 'manager') as managers;

-- ========================================
-- RECOMENDAÇÕES
-- ========================================

-- Mostrar recomendações baseadas no diagnóstico
DO $$
DECLARE
  usuarios_sem_senha INTEGER;
  usuarios_duplicados INTEGER;
BEGIN
  SELECT COUNT(*) INTO usuarios_sem_senha FROM public.profiles WHERE password_hash IS NULL;
  SELECT COUNT(*) INTO usuarios_duplicados FROM (
    SELECT email FROM public.profiles GROUP BY email HAVING COUNT(*) > 1
  ) t;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RECOMENDAÇÕES';
  RAISE NOTICE '========================================';
  
  IF usuarios_sem_senha > 0 THEN
    RAISE NOTICE '⚠️  % usuários sem senha hash - precisam ter senhas definidas', usuarios_sem_senha;
  END IF;
  
  IF usuarios_duplicados > 0 THEN
    RAISE NOTICE '⚠️  % emails duplicados encontrados - precisam ser corrigidos', usuarios_duplicados;
  END IF;
  
  RAISE NOTICE '💡 Execute SINCRONIZAR_USUARIOS_HARDCODED.sql para corrigir problemas';
  RAISE NOTICE '💡 Execute CORRIGIR_CRIACAO_USUARIOS.sql para melhorar sistema de autenticação';
END $$;