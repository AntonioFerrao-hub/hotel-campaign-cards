-- ========================================
-- SISTEMA DE USUÁRIOS COMPLETO - DO ZERO
-- ========================================
-- Execute este script no Supabase Dashboard para criar sistema completo

-- ========================================
-- PASSO 1: LIMPAR SISTEMA ANTIGO (OPCIONAL)
-- ========================================

-- Remover tabela profiles antiga se existir (CUIDADO: isso apaga dados!)
-- DROP TABLE IF EXISTS public.profiles CASCADE;

-- Remover funções antigas
DROP FUNCTION IF EXISTS public.authenticate_user CASCADE;
DROP FUNCTION IF EXISTS public.create_user_with_password CASCADE;
DROP FUNCTION IF EXISTS public.hash_password CASCADE;
DROP FUNCTION IF EXISTS public.verify_password CASCADE;
DROP FUNCTION IF EXISTS public.upsert_hardcoded_user CASCADE;

-- ========================================
-- PASSO 2: CRIAR TABELA "USER" NOVA
-- ========================================

CREATE TABLE IF NOT EXISTS public.user (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  password_hash TEXT NOT NULL,
  role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'manager', 'user')),
  active BOOLEAN DEFAULT true,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_user_email ON public.user(email);
CREATE INDEX IF NOT EXISTS idx_user_role ON public.user(role);
CREATE INDEX IF NOT EXISTS idx_user_active ON public.user(active);

-- ========================================
-- PASSO 3: CRIAR FUNÇÕES DE HASH E VERIFICAÇÃO
-- ========================================

-- Função para hash de senha
CREATE OR REPLACE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN crypt(password, gen_salt('bf', 10));
END;
$$;

-- Função para verificar senha
CREATE OR REPLACE FUNCTION public.verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN crypt(password, hash) = hash;
END;
$$;

-- ========================================
-- PASSO 4: CRIAR FUNÇÃO DE AUTENTICAÇÃO
-- ========================================

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
AS $$
DECLARE
  user_record RECORD;
BEGIN
  -- Buscar usuário ativo na tabela user
  SELECT id, name, email, role, password_hash, active
  INTO user_record
  FROM public.user
  WHERE email = user_email AND active = true;
  
  -- Verificar se usuário existe
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, NULL::TEXT, 'Usuário não encontrado ou inativo'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar senha
  IF public.verify_password(user_password, user_record.password_hash) THEN
    -- Atualizar último login
    UPDATE public.user 
    SET last_login = NOW(), updated_at = NOW()
    WHERE id = user_record.id;
    
    RETURN QUERY SELECT TRUE, user_record.id, user_record.name, user_record.role, 'Login realizado com sucesso'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE, user_record.id, user_record.name, user_record.role, 'Senha incorreta'::TEXT;
  END IF;
END;
$$;

-- ========================================
-- PASSO 5: CRIAR FUNÇÃO PARA CRIAR USUÁRIO
-- ========================================

CREATE OR REPLACE FUNCTION public.create_user(
  user_email TEXT,
  user_name TEXT,
  user_password TEXT,
  user_role TEXT DEFAULT 'user'
)
RETURNS TABLE(
  success BOOLEAN,
  user_id UUID,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Verificar se email já existe
  IF EXISTS (SELECT 1 FROM public.user WHERE email = user_email) THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Email já está em uso'::TEXT;
    RETURN;
  END IF;
  
  -- Criar novo usuário
  INSERT INTO public.user (email, name, password_hash, role)
  VALUES (user_email, user_name, public.hash_password(user_password), user_role)
  RETURNING id INTO new_user_id;
  
  RETURN QUERY SELECT TRUE, new_user_id, 'Usuário criado com sucesso'::TEXT;
  
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT FALSE, NULL::UUID, ('Erro ao criar usuário: ' || SQLERRM)::TEXT;
END;
$$;

-- ========================================
-- PASSO 6: CRIAR FUNÇÃO PARA ATUALIZAR USUÁRIO
-- ========================================

CREATE OR REPLACE FUNCTION public.update_user(
  user_id UUID,
  user_name TEXT DEFAULT NULL,
  user_email TEXT DEFAULT NULL,
  user_password TEXT DEFAULT NULL,
  user_role TEXT DEFAULT NULL,
  user_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verificar se usuário existe
  IF NOT EXISTS (SELECT 1 FROM public.user WHERE id = user_id) THEN
    RETURN QUERY SELECT FALSE, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar se email já está em uso por outro usuário
  IF user_email IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.user WHERE email = user_email AND id != user_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Email já está em uso por outro usuário'::TEXT;
    RETURN;
  END IF;
  
  -- Atualizar campos fornecidos
  UPDATE public.user
  SET 
    name = COALESCE(user_name, name),
    email = COALESCE(user_email, email),
    password_hash = CASE 
      WHEN user_password IS NOT NULL THEN public.hash_password(user_password)
      ELSE password_hash
    END,
    role = COALESCE(user_role, role),
    active = COALESCE(user_active, active),
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN QUERY SELECT TRUE, 'Usuário atualizado com sucesso'::TEXT;
  
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT FALSE, ('Erro ao atualizar usuário: ' || SQLERRM)::TEXT;
END;
$$;

-- ========================================
-- PASSO 7: CRIAR FUNÇÃO PARA DELETAR USUÁRIO
-- ========================================

CREATE OR REPLACE FUNCTION public.delete_user(user_id UUID)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verificar se usuário existe
  IF NOT EXISTS (SELECT 1 FROM public.user WHERE id = user_id) THEN
    RETURN QUERY SELECT FALSE, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Soft delete - marcar como inativo
  UPDATE public.user
  SET active = false, updated_at = NOW()
  WHERE id = user_id;
  
  RETURN QUERY SELECT TRUE, 'Usuário desativado com sucesso'::TEXT;
  
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT FALSE, ('Erro ao deletar usuário: ' || SQLERRM)::TEXT;
END;
$$;

-- ========================================
-- PASSO 8: CRIAR FUNÇÃO PARA LISTAR USUÁRIOS
-- ========================================

CREATE OR REPLACE FUNCTION public.get_users(
  include_inactive BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(
  id UUID,
  email TEXT,
  name TEXT,
  role TEXT,
  active BOOLEAN,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF include_inactive THEN
    RETURN QUERY 
    SELECT u.id, u.email, u.name, u.role, u.active, u.last_login, u.created_at, u.updated_at
    FROM public.user u
    ORDER BY u.created_at DESC;
  ELSE
    RETURN QUERY 
    SELECT u.id, u.email, u.name, u.role, u.active, u.last_login, u.created_at, u.updated_at
    FROM public.user u
    WHERE u.active = true
    ORDER BY u.created_at DESC;
  END IF;
END;
$$;

-- ========================================
-- PASSO 9: CRIAR FUNÇÃO PARA BUSCAR USUÁRIO POR ID
-- ========================================

CREATE OR REPLACE FUNCTION public.get_user_by_id(user_id UUID)
RETURNS TABLE(
  id UUID,
  email TEXT,
  name TEXT,
  role TEXT,
  active BOOLEAN,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY 
  SELECT u.id, u.email, u.name, u.role, u.active, u.last_login, u.created_at, u.updated_at
  FROM public.user u
  WHERE u.id = user_id;
END;
$$;

-- ========================================
-- PASSO 10: CONFIGURAR PERMISSÕES
-- ========================================

-- Permissões para usuários autenticados
GRANT SELECT, INSERT, UPDATE ON public.user TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Permissões para usuários anônimos (apenas para login)
GRANT EXECUTE ON FUNCTION public.authenticate_user TO anon;
GRANT EXECUTE ON FUNCTION public.hash_password TO anon;
GRANT EXECUTE ON FUNCTION public.verify_password TO anon;

-- ========================================
-- PASSO 11: CONFIGURAR RLS (Row Level Security)
-- ========================================

-- Habilitar RLS
ALTER TABLE public.user ENABLE ROW LEVEL SECURITY;

-- Política para admins verem todos os usuários
CREATE POLICY "Admins can view all users"
  ON public.user FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user 
      WHERE id = auth.uid() AND role = 'admin' AND active = true
    )
  );

-- Política para usuários verem apenas seu próprio perfil
CREATE POLICY "Users can view own profile"
  ON public.user FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Política para admins atualizarem qualquer usuário
CREATE POLICY "Admins can update all users"
  ON public.user FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user 
      WHERE id = auth.uid() AND role = 'admin' AND active = true
    )
  );

-- Política para usuários atualizarem apenas seu próprio perfil
CREATE POLICY "Users can update own profile"
  ON public.user FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

-- ========================================
-- PASSO 12: CRIAR USUÁRIOS INICIAIS
-- ========================================

-- Criar usuário admin
SELECT public.create_user(
  'admin@hotel.com.br',
  'Administrador do Sistema',
  'admin123',
  'admin'
);

-- Criar usuário de teste
SELECT public.create_user(
  'user@hotel.com.br',
  'Usuário de Teste',
  'user123',
  'user'
);

-- Criar usuário de suporte
SELECT public.create_user(
  'suporte@wfinformatica.com.br',
  'Suporte WF Informática',
  'suporte123',
  'admin'
);

-- Criar usuário manager
SELECT public.create_user(
  'manager@hotel.com.br',
  'Gerente do Hotel',
  'manager123',
  'manager'
);

-- ========================================
-- PASSO 13: TRIGGER PARA UPDATED_AT
-- ========================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_user_updated_at ON public.user;
CREATE TRIGGER update_user_updated_at
  BEFORE UPDATE ON public.user
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ========================================
-- PASSO 14: VERIFICAÇÃO FINAL
-- ========================================

DO $$
DECLARE
  total_users INTEGER;
  admin_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_users FROM public.user WHERE active = true;
  SELECT COUNT(*) INTO admin_count FROM public.user WHERE role = 'admin' AND active = true;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SISTEMA DE USUÁRIOS CRIADO COM SUCESSO!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total de usuários ativos: %', total_users;
  RAISE NOTICE 'Administradores: %', admin_count;
  RAISE NOTICE '';
  RAISE NOTICE 'CREDENCIAIS PARA TESTE:';
  RAISE NOTICE '- admin@hotel.com.br / admin123 (admin)';
  RAISE NOTICE '- user@hotel.com.br / user123 (user)';
  RAISE NOTICE '- suporte@wfinformatica.com.br / suporte123 (admin)';
  RAISE NOTICE '- manager@hotel.com.br / manager123 (manager)';
  RAISE NOTICE '';
  RAISE NOTICE 'FUNÇÕES DISPONÍVEIS:';
  RAISE NOTICE '- authenticate_user(email, password)';
  RAISE NOTICE '- create_user(email, name, password, role)';
  RAISE NOTICE '- update_user(id, name, email, password, role, active)';
  RAISE NOTICE '- delete_user(id)';
  RAISE NOTICE '- get_users(include_inactive)';
  RAISE NOTICE '- get_user_by_id(id)';
  RAISE NOTICE '';
  RAISE NOTICE 'Sistema pronto para uso!';
END $$;