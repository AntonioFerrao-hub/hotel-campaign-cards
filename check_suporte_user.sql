-- ========================================
-- VERIFICAR USUÁRIO suporte@wfinformatica.com.br
-- ========================================

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
WHERE email = 'suporte@wfinformatica.com.br';

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
WHERE email = 'suporte@wfinformatica.com.br';

-- 3. Verificar todos os usuários em auth.users (para comparação)
SELECT 
  'TODOS_AUTH_USERS' as info,
  COUNT(*) as total_usuarios
FROM auth.users;

-- 4. Verificar todos os usuários em profiles (para comparação)
SELECT 
  'TODOS_PROFILES' as info,
  COUNT(*) as total_profiles
FROM public.profiles;

-- 5. Listar primeiros 5 usuários de cada tabela para referência
SELECT 
  'SAMPLE_AUTH_USERS' as tipo,
  email,
  created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

SELECT 
  'SAMPLE_PROFILES' as tipo,
  email,
  name,
  role,
  created_at
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 5;

-- 6. Verificar se há usuários órfãos (em profiles mas não em auth.users)
SELECT 
  'USUARIOS_ORFAOS' as tipo,
  p.email,
  p.name,
  p.role
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL;

-- 7. Verificar se há usuários auth sem profile
SELECT 
  'AUTH_SEM_PROFILE' as tipo,
  au.email,
  au.created_at
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL;