-- ========================================
-- CRIAR PROFILE PARA USUÁRIO SUPORTE
-- ========================================

-- Inserir registro na tabela profiles para o usuário suporte@wfinformatica.com.br
-- ID obtido do teste: f99fee1a-fb9b-4f9e-bb1f-94d85e795c4e

INSERT INTO public.profiles (
  id,
  name,
  email,
  role,
  created_at,
  updated_at
) VALUES (
  'f99fee1a-fb9b-4f9e-bb1f-94d85e795c4e',
  'Suporte WF Informática',
  'suporte@wfinformatica.com.br',
  'admin',
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  role = EXCLUDED.role,
  updated_at = NOW();

-- Verificar se o registro foi criado corretamente
SELECT 
  'PROFILE_CRIADO' as status,
  id,
  name,
  email,
  role,
  created_at,
  updated_at
FROM public.profiles 
WHERE email = 'suporte@wfinformatica.com.br';

-- Verificar se agora temos sincronização entre auth.users e profiles
SELECT 
  'SINCRONIZACAO_VERIFICADA' as status,
  au.email as auth_email,
  p.email as profile_email,
  p.name as profile_name,
  p.role as profile_role
FROM auth.users au
INNER JOIN public.profiles p ON p.id = au.id
WHERE au.email = 'suporte@wfinformatica.com.br';