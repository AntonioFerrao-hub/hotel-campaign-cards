-- ========================================
-- MIGRAÇÃO PARA SUPABASE AUTH NATIVO
-- ========================================
-- Este script migra o sistema atual para usar apenas Supabase Auth nativo
-- eliminando o sistema híbrido que causa o erro "Usuário não autenticado"

-- ========================================
-- PASSO 1: MIGRAR USUÁRIOS PARA AUTH.USERS
-- ========================================

-- Função para migrar usuários existentes da tabela profiles para auth.users
CREATE OR REPLACE FUNCTION migrate_profiles_to_auth()
RETURNS TEXT AS $$
DECLARE
  profile_record RECORD;
  migrated_count INTEGER := 0;
  error_count INTEGER := 0;
  result_text TEXT;
BEGIN
  -- Iterar sobre todos os perfis que não existem em auth.users
  FOR profile_record IN 
    SELECT p.id, p.email, p.name, p.role
    FROM public.profiles p
    LEFT JOIN auth.users au ON au.id = p.id
    WHERE au.id IS NULL
  LOOP
    BEGIN
      -- Criar usuário no auth.users usando admin API
      -- NOTA: Este passo deve ser feito via código TypeScript/JavaScript
      -- pois SQL não pode criar usuários diretamente em auth.users
      
      -- Por enquanto, apenas logamos os usuários que precisam ser migrados
      RAISE NOTICE 'Usuário a ser migrado: ID=%, Email=%, Nome=%', 
        profile_record.id, profile_record.email, profile_record.name;
      
      migrated_count := migrated_count + 1;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Erro ao migrar usuário %: %', profile_record.email, SQLERRM;
      error_count := error_count + 1;
    END;
  END LOOP;
  
  result_text := format('Migração concluída. Usuários identificados: %s, Erros: %s', 
                       migrated_count, error_count);
  
  RETURN result_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- PASSO 2: TRIGGER PARA SINCRONIZAÇÃO AUTOMÁTICA
-- ========================================

-- Função trigger para criar perfil automaticamente quando usuário é criado
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

-- Criar trigger para novos usuários
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- PASSO 3: ATUALIZAR FUNÇÕES EXISTENTES
-- ========================================

-- Função corrigida para atualizar perfil (agora funciona com auth.uid())
CREATE OR REPLACE FUNCTION public.update_user_profile_native(
  target_user_id UUID,
  new_name TEXT DEFAULT NULL,
  new_email TEXT DEFAULT NULL,
  new_role TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  current_user_role TEXT;
  current_user_id UUID;
  old_data JSONB;
  updated_data JSONB;
BEGIN
  current_user_id := auth.uid();
  
  -- Verificar se usuário está autenticado (agora funciona!)
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;
  
  -- Verificar permissões
  SELECT role INTO current_user_role 
  FROM public.profiles 
  WHERE id = current_user_id;
  
  IF current_user_role IS NULL THEN
    RAISE EXCEPTION 'Perfil do usuário atual não encontrado';
  END IF;
  
  -- Apenas admins podem alterar outros usuários ou alterar roles
  IF current_user_role != 'admin' AND (current_user_id != target_user_id OR new_role IS NOT NULL) THEN
    RAISE EXCEPTION 'Sem permissão para atualizar este usuário ou alterar função';
  END IF;
  
  -- Verificar se usuário alvo existe
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = target_user_id) THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;
  
  -- Capturar dados antigos para auditoria
  SELECT jsonb_build_object(
    'name', name,
    'email', email,
    'role', role
  ) INTO old_data
  FROM public.profiles 
  WHERE id = target_user_id;
  
  -- Validações
  IF new_email IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE email = new_email AND id != target_user_id
  ) THEN
    RAISE EXCEPTION 'Email já está em uso por outro usuário';
  END IF;
  
  IF new_name IS NOT NULL AND LENGTH(TRIM(new_name)) < 2 THEN
    RAISE EXCEPTION 'Nome deve ter pelo menos 2 caracteres';
  END IF;
  
  IF new_email IS NOT NULL AND new_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'Email deve ter um formato válido';
  END IF;
  
  IF new_role IS NOT NULL AND new_role NOT IN ('user', 'manager', 'admin') THEN
    RAISE EXCEPTION 'Função deve ser: user, manager ou admin';
  END IF;
  
  -- Atualizar campos fornecidos
  UPDATE public.profiles 
  SET 
    name = CASE WHEN new_name IS NOT NULL THEN TRIM(new_name) ELSE name END,
    email = CASE WHEN new_email IS NOT NULL THEN LOWER(TRIM(new_email)) ELSE email END,
    role = CASE 
      WHEN new_role IS NOT NULL AND current_user_role = 'admin' THEN new_role
      ELSE role 
    END,
    updated_at = now()
  WHERE id = target_user_id;
  
  -- Capturar dados atualizados
  SELECT jsonb_build_object(
    'id', id,
    'name', name,
    'email', email,
    'role', role,
    'updated_at', updated_at
  ) INTO updated_data
  FROM public.profiles 
  WHERE id = target_user_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Usuário atualizado com sucesso!',
    'user', updated_data
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erro ao atualizar usuário: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- PASSO 4: POLÍTICAS RLS ATUALIZADAS
-- ========================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- Criar políticas RLS que funcionam com auth.uid()
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can update all profiles" ON public.profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert profiles" ON public.profiles
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ========================================
-- PASSO 5: GRANTS E PERMISSÕES
-- ========================================

GRANT EXECUTE ON FUNCTION public.migrate_profiles_to_auth() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_profile_native(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;

-- ========================================
-- INSTRUÇÕES DE MIGRAÇÃO
-- ========================================

/*
PASSOS PARA MIGRAÇÃO COMPLETA:

1. EXECUTAR ESTE SCRIPT NO SUPABASE DASHBOARD

2. MIGRAR USUÁRIOS EXISTENTES (via código TypeScript):
   - Use a Admin API do Supabase para criar usuários em auth.users
   - Para cada perfil em public.profiles, criar usuário correspondente

3. ATUALIZAR O FRONTEND:
   - Substituir AuthContext customizado por useAuth do Supabase
   - Usar supabase.auth.signInWithPassword() em vez de RPC customizado
   - Remover verify_user_password e funções relacionadas

4. TESTAR:
   - Login com Supabase Auth nativo
   - Verificar se auth.uid() retorna valores corretos
   - Testar atualização de usuários

5. LIMPEZA:
   - Remover funções antigas (verify_user_password, etc.)
   - Remover código de autenticação customizado
*/

-- Verificar migração
SELECT 'Migração preparada. Execute os passos manuais descritos acima.' as status;