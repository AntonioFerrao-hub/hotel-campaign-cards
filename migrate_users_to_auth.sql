-- ========================================
-- VERIFICAÇÃO E SINCRONIZAÇÃO DE USUÁRIOS
-- ========================================

-- 1. Verificar usuários existentes em profiles
SELECT 
  'PROFILES' as tabela,
  COUNT(*) as total_usuarios,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admins,
  COUNT(CASE WHEN role = 'manager' THEN 1 END) as managers,
  COUNT(CASE WHEN role = 'user' THEN 1 END) as users
FROM public.profiles;

-- 2. Verificar usuários existentes em auth.users
SELECT 
  'AUTH_USERS' as tabela,
  COUNT(*) as total_usuarios
FROM auth.users;

-- 3. Verificar correspondência entre profiles e auth.users
SELECT 
  p.id,
  p.name,
  p.email,
  p.role,
  CASE 
    WHEN au.id IS NOT NULL THEN 'EXISTE_EM_AUTH'
    ELSE 'FALTA_EM_AUTH'
  END as status_auth
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
ORDER BY p.created_at;

-- 4. Verificar usuários em auth.users sem profile
SELECT 
  au.id,
  au.email,
  au.created_at,
  CASE 
    WHEN p.id IS NOT NULL THEN 'TEM_PROFILE'
    ELSE 'FALTA_PROFILE'
  END as status_profile
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
ORDER BY au.created_at;

-- ========================================
-- FUNÇÃO PARA SINCRONIZAR USUÁRIOS
-- ========================================

-- Função para criar profiles para usuários auth sem profile
CREATE OR REPLACE FUNCTION sync_auth_users_to_profiles()
RETURNS TEXT AS $$
DECLARE
  auth_user RECORD;
  created_count INTEGER := 0;
  result_text TEXT;
BEGIN
  -- Criar profiles para usuários auth que não têm profile
  FOR auth_user IN 
    SELECT au.id, au.email, au.created_at
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.id IS NULL
  LOOP
    INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
    VALUES (
      auth_user.id,
      COALESCE(auth_user.email, 'Usuário'),
      auth_user.email,
      'user', -- Role padrão
      auth_user.created_at,
      NOW()
    );
    
    created_count := created_count + 1;
    RAISE NOTICE 'Profile criado para usuário: %', auth_user.email;
  END LOOP;
  
  result_text := format('Sincronização concluída. Profiles criados: %s', created_count);
  RETURN result_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- ATUALIZAR TRIGGER PARA NOVOS USUÁRIOS
-- ========================================

-- Função trigger atualizada para criar perfil automaticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recriar trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- GRANTS
-- ========================================

GRANT EXECUTE ON FUNCTION sync_auth_users_to_profiles() TO authenticated;

-- ========================================
-- EXECUTAR SINCRONIZAÇÃO
-- ========================================

-- Executar sincronização
SELECT sync_auth_users_to_profiles();

-- Verificar resultado final
SELECT 
  'RESULTADO_FINAL' as status,
  (SELECT COUNT(*) FROM public.profiles) as total_profiles,
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM public.profiles p INNER JOIN auth.users au ON au.id = p.id) as usuarios_sincronizados;