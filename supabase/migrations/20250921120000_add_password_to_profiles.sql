-- ========================================
-- MIGRAÇÃO: ADICIONAR AUTENTICAÇÃO DIRETA NO PROFILES
-- ========================================
-- Esta migração adiciona autenticação customizada diretamente na tabela profiles
-- sem depender do Supabase Auth

-- Passo 1: Adicionar campo de senha na tabela profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Passo 2: Criar função para hash de senha usando crypt
CREATE OR REPLACE FUNCTION public.hash_password(password TEXT)
RETURNS TEXT AS $$
BEGIN
  -- Usar crypt com salt bcrypt para hash seguro
  RETURN crypt(password, gen_salt('bf', 10));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 3: Criar função para verificar senha
CREATE OR REPLACE FUNCTION public.verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Verificar se a senha corresponde ao hash
  RETURN (crypt(password, hash) = hash);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 4: Criar função de login customizada
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
) AS $$
DECLARE
  profile_record public.profiles%ROWTYPE;
BEGIN
  -- Buscar usuário pelo email
  SELECT * INTO profile_record
  FROM public.profiles
  WHERE email = lower(trim(user_email));
  
  -- Verificar se usuário existe
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, NULL::UUID, NULL::TEXT, NULL::TEXT, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar se tem senha configurada
  IF profile_record.password_hash IS NULL THEN
    RETURN QUERY SELECT false, profile_record.id, profile_record.name, profile_record.role, 'Senha não configurada para este usuário'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar senha
  IF NOT public.verify_password(user_password, profile_record.password_hash) THEN
    RETURN QUERY SELECT false, profile_record.id, profile_record.name, profile_record.role, 'Senha incorreta'::TEXT;
    RETURN;
  END IF;
  
  -- Login bem-sucedido
  RETURN QUERY SELECT true, profile_record.id, profile_record.name, profile_record.role, 'Login realizado com sucesso'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 5: Criar função para definir senha de usuário
CREATE OR REPLACE FUNCTION public.set_user_password(
  target_user_id UUID,
  new_password TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Atualizar senha do usuário
  UPDATE public.profiles
  SET 
    password_hash = public.hash_password(new_password),
    updated_at = now()
  WHERE id = target_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 6: Criar função para criar usuário com senha
CREATE OR REPLACE FUNCTION public.create_user_with_custom_auth(
  user_name TEXT,
  user_email TEXT,
  user_password TEXT,
  user_role TEXT DEFAULT 'user'
)
RETURNS TABLE(
  success BOOLEAN,
  user_id UUID,
  message TEXT
) AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Gerar novo ID
  new_user_id := gen_random_uuid();
  
  -- Inserir usuário
  INSERT INTO public.profiles (id, name, email, role, password_hash, created_at, updated_at)
  VALUES (
    new_user_id,
    user_name,
    lower(trim(user_email)),
    user_role,
    public.hash_password(user_password),
    now(),
    now()
  );
  
  RETURN QUERY SELECT true, new_user_id, 'Usuário criado com sucesso'::TEXT;
  
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, NULL::UUID, 'Email já está em uso'::TEXT;
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, NULL::UUID, ('Erro ao criar usuário: ' || SQLERRM)::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 7: Criar função para atualizar senha
CREATE OR REPLACE FUNCTION public.change_user_password(
  user_email TEXT,
  current_password TEXT,
  new_password TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  profile_record public.profiles%ROWTYPE;
BEGIN
  -- Buscar usuário
  SELECT * INTO profile_record
  FROM public.profiles
  WHERE email = lower(trim(user_email));
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Verificar senha atual
  IF NOT public.verify_password(current_password, profile_record.password_hash) THEN
    RETURN QUERY SELECT false, 'Senha atual incorreta'::TEXT;
    RETURN;
  END IF;
  
  -- Atualizar senha
  UPDATE public.profiles
  SET 
    password_hash = public.hash_password(new_password),
    updated_at = now()
  WHERE id = profile_record.id;
  
  RETURN QUERY SELECT true, 'Senha alterada com sucesso'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 8: Definir senhas padrão para usuários existentes
-- Definir senha padrão "123456" para todos os usuários existentes que não têm senha
UPDATE public.profiles 
SET password_hash = public.hash_password('123456')
WHERE password_hash IS NULL;

-- Passo 9: Conceder permissões
GRANT EXECUTE ON FUNCTION public.hash_password(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.verify_password(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.authenticate_user(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.set_user_password(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_custom_auth(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.change_user_password(TEXT, TEXT, TEXT) TO authenticated, anon;

-- Passo 10: Atualizar políticas RLS para permitir autenticação customizada
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

-- Nova política para permitir leitura durante autenticação
CREATE POLICY "Allow profile access for authentication" 
ON public.profiles 
FOR SELECT 
USING (true); -- Permitir leitura para autenticação

-- Política para permitir atualizações por admins ou próprio usuário
CREATE POLICY "Allow profile updates by admin or self" 
ON public.profiles 
FOR UPDATE 
USING (
  role = 'admin' OR 
  id = auth.uid() OR
  auth.role() = 'service_role'
);

-- Política para permitir inserção por admins
CREATE POLICY "Allow profile creation by admin" 
ON public.profiles 
FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ) OR
  auth.role() = 'service_role'
);

-- Política para permitir exclusão por admins
CREATE POLICY "Allow profile deletion by admin" 
ON public.profiles 
FOR DELETE 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ) OR
  auth.role() = 'service_role'
);

-- Passo 11: Criar função para atualizar senha por admin (para UserManagement)
CREATE OR REPLACE FUNCTION public.update_user_password(
  target_user_id UUID,
  new_password TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT
) AS $$
BEGIN
  -- Verificar se o usuário existe
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = target_user_id) THEN
    RETURN QUERY SELECT false, 'Usuário não encontrado'::TEXT;
    RETURN;
  END IF;
  
  -- Atualizar senha
  UPDATE public.profiles
  SET 
    password_hash = public.hash_password(new_password),
    updated_at = now()
  WHERE id = target_user_id;
  
  RETURN QUERY SELECT true, 'Senha alterada com sucesso'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 12: Criar função para criar usuário com senha (para UserManagement)
CREATE OR REPLACE FUNCTION public.create_user_with_password(
  user_email TEXT,
  user_name TEXT,
  user_password TEXT,
  user_role TEXT,
  user_hotel_ids UUID[] DEFAULT '{}'
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  user_id UUID
) AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Gerar novo ID
  new_user_id := gen_random_uuid();
  
  -- Inserir usuário
  INSERT INTO public.profiles (id, name, email, role, password_hash, created_at, updated_at)
  VALUES (
    new_user_id,
    user_name,
    lower(trim(user_email)),
    user_role,
    public.hash_password(user_password),
    now(),
    now()
  );
  
  RETURN QUERY SELECT true, 'Usuário criado com sucesso'::TEXT, new_user_id;
  
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Email já está em uso'::TEXT, NULL::UUID;
  WHEN OTHERS THEN
    RETURN QUERY SELECT false, ('Erro ao criar usuário: ' || SQLERRM)::TEXT, NULL::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Passo 13: Conceder permissões para as novas funções
GRANT EXECUTE ON FUNCTION public.update_user_password(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, UUID[]) TO authenticated;

-- Comentário final
COMMENT ON TABLE public.profiles IS 'Tabela de usuários com autenticação customizada integrada';
COMMENT ON COLUMN public.profiles.password_hash IS 'Hash bcrypt da senha do usuário';