-- ========================================
-- EXECUTE NO SUPABASE DASHBOARD
-- ========================================
-- Vá para: https://supabase.com/dashboard/project/mpdblvvznqpajascuxxb/sql
-- Cole este código e execute para verificar o usuário suporte05@wfinformatica.com.br

-- DIAGNÓSTICO COMPLETO DO USUÁRIO suporte05@wfinformatica.com.br

-- 1. Verificar se existe na tabela auth.users
SELECT 
  'AUTH_USERS' as tabela,
  id,
  email,
  email_confirmed_at,
  created_at,
  updated_at,
  last_sign_in_at,
  raw_user_meta_data
FROM auth.users 
WHERE email = 'suporte05@wfinformatica.com.br';

-- 2. Verificar se existe na tabela profiles
SELECT 
  'PROFILES' as tabela,
  id,
  name,
  email,
  role,
  created_at,
  updated_at
FROM public.profiles 
WHERE email = 'suporte05@wfinformatica.com.br';

-- 3. Verificar se há usuários órfãos (em profiles mas não em auth.users)
SELECT 
  'USUARIO_ORFAO' as tipo,
  p.id,
  p.email,
  p.name,
  p.role,
  p.created_at
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL AND p.email = 'suporte05@wfinformatica.com.br';

-- 4. Verificar se há usuário auth sem profile
SELECT 
  'AUTH_SEM_PROFILE' as tipo,
  au.id,
  au.email,
  au.created_at,
  au.email_confirmed_at
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL AND au.email = 'suporte05@wfinformatica.com.br';

-- 5. Verificar todos os usuários similares (suporte*)
SELECT 
  'USUARIOS_SUPORTE' as tipo,
  'profiles' as origem,
  id,
  name,
  email,
  role,
  created_at
FROM public.profiles 
WHERE email LIKE 'suporte%@wfinformatica.com.br'
ORDER BY email;

-- 6. Verificar logs de auditoria relacionados ao usuário (se existir)
SELECT 
  'AUDIT_LOGS' as tipo,
  ual.id,
  ual.user_id,
  ual.action,
  ual.old_data,
  ual.new_data,
  ual.performed_by,
  ual.created_at,
  p.email as user_email,
  pb.email as performed_by_email
FROM public.user_audit_log ual
LEFT JOIN public.profiles p ON p.id = ual.user_id
LEFT JOIN public.profiles pb ON pb.id = ual.performed_by
WHERE p.email = 'suporte05@wfinformatica.com.br' 
   OR ual.old_data::text LIKE '%suporte05@wfinformatica.com.br%'
ORDER BY ual.created_at DESC;

-- 7. Diagnóstico do problema
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'suporte05@wfinformatica.com.br') 
     AND EXISTS (SELECT 1 FROM public.profiles WHERE email = 'suporte05@wfinformatica.com.br')
    THEN 'USUARIO_COMPLETO - Usuário existe em ambas as tabelas'
    
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'suporte05@wfinformatica.com.br') 
     AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE email = 'suporte05@wfinformatica.com.br')
    THEN 'FALTA_PROFILE - Usuário existe em auth.users mas não tem profile'
    
    WHEN NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'suporte05@wfinformatica.com.br') 
     AND EXISTS (SELECT 1 FROM public.profiles WHERE email = 'suporte05@wfinformatica.com.br')
    THEN 'PROFILE_ORFAO - Profile existe mas não há usuário em auth.users'
    
    ELSE 'USUARIO_NAO_EXISTE - Usuário não existe em nenhuma tabela'
  END as diagnostico;

-- ========================================
-- INSTRUÇÕES APÓS EXECUTAR:
-- ========================================
-- 1. Execute este script no dashboard do Supabase
-- 2. Analise os resultados para identificar o problema específico
-- 3. Com base no diagnóstico, aplicaremos a correção adequada:
--    - Se FALTA_PROFILE: Criar profile para o usuário auth existente
--    - Se PROFILE_ORFAO: Criar usuário auth ou remover profile órfão
--    - Se USUARIO_NAO_EXISTE: Criar usuário completo
--    - Se USUARIO_COMPLETO: Investigar problema de login/permissões
-- ========================================