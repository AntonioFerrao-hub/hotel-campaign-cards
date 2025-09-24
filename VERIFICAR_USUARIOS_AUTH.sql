-- ========================================
-- DIAGNÓSTICO: VERIFICAR USUÁRIOS AUTH
-- ========================================
-- Execute este script no Supabase Dashboard para diagnosticar o problema

-- 1. Verificar usuários na tabela profiles
SELECT 
  'PROFILES' as tabela,
  COUNT(*) as total_usuarios,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admins,
  COUNT(CASE WHEN role = 'manager' THEN 1 END) as managers,
  COUNT(CASE WHEN role = 'user' THEN 1 END) as users
FROM public.profiles;

-- 2. Listar todos os usuários em profiles
SELECT 
  id,
  name,
  email,
  role,
  created_at,
  password_hash IS NOT NULL as tem_senha_hash
FROM public.profiles
ORDER BY created_at DESC;

-- 3. Verificar se existem usuários em auth.users
-- (Esta consulta pode falhar se não tivermos permissão)
SELECT 
  'AUTH_USERS' as tabela,
  COUNT(*) as total_usuarios
FROM auth.users;

-- 4. Verificar correspondência entre profiles e auth.users
SELECT 
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

-- 5. Verificar usuários em auth.users sem profile
SELECT 
  au.id,
  au.email,
  au.created_at,
  au.email_confirmed_at IS NOT NULL as email_confirmado,
  CASE 
    WHEN p.id IS NOT NULL THEN 'TEM_PROFILE'
    ELSE 'FALTA_PROFILE'
  END as status_profile
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
ORDER BY au.created_at DESC;

-- 6. Verificar se a função authenticate_user existe
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'authenticate_user';

-- 7. Verificar se a função create_user_with_password existe
SELECT 
  routine_name,
  routine_type,
  specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'create_user_with_password';

-- 8. Verificar triggers em auth.users
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users';

-- ========================================
-- RESUMO DO DIAGNÓSTICO
-- ========================================

-- Mostrar resumo final
SELECT 
  'RESUMO_DIAGNOSTICO' as status,
  (SELECT COUNT(*) FROM public.profiles) as total_profiles,
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM public.profiles p INNER JOIN auth.users au ON au.id = p.id) as usuarios_sincronizados,
  (SELECT COUNT(*) FROM public.profiles WHERE password_hash IS NOT NULL) as profiles_com_senha;