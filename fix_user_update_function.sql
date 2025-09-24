-- Corrigir função de atualização de usuário
-- Este arquivo corrige problemas na atualização da função do usuário

-- 1. Função para atualizar perfil de usuário (corrigida)
CREATE OR REPLACE FUNCTION public.update_user_profile(
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
  changes_made BOOLEAN := false;
BEGIN
  current_user_id := auth.uid();
  
  -- Verificar se usuário está autenticado
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
  
  -- Validar email único se fornecido
  IF new_email IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE email = new_email AND id != target_user_id
  ) THEN
    RAISE EXCEPTION 'Email já está em uso por outro usuário';
  END IF;
  
  -- Validar dados de entrada
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
  
  -- Verificar se houve mudanças
  GET DIAGNOSTICS changes_made = ROW_COUNT;
  
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
  
  -- Log da auditoria
  INSERT INTO public.user_audit_log (user_id, action, old_data, new_data, performed_by)
  VALUES (
    target_user_id,
    'UPDATE',
    old_data,
    updated_data,
    current_user_id
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Usuário atualizado com sucesso!',
    'user', updated_data,
    'changes_made', changes_made
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

-- 2. Nova função para alterar senha de usuário
CREATE OR REPLACE FUNCTION public.update_user_password(
  target_user_id UUID,
  new_password TEXT,
  current_password TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  current_user_role TEXT;
  current_user_id UUID;
  target_user_email TEXT;
BEGIN
  current_user_id := auth.uid();
  
  -- Verificar se usuário está autenticado
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;
  
  -- Verificar permissões
  SELECT role INTO current_user_role 
  FROM public.profiles 
  WHERE id = current_user_id;
  
  -- Apenas admins podem alterar senha de outros usuários
  IF current_user_role != 'admin' AND current_user_id != target_user_id THEN
    RAISE EXCEPTION 'Sem permissão para alterar senha deste usuário';
  END IF;
  
  -- Verificar se usuário alvo existe
  SELECT email INTO target_user_email
  FROM public.profiles 
  WHERE id = target_user_id;
  
  IF target_user_email IS NULL THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;
  
  -- Validar nova senha
  IF new_password IS NULL OR LENGTH(new_password) < 6 THEN
    RAISE EXCEPTION 'Nova senha deve ter pelo menos 6 caracteres';
  END IF;
  
  -- Log da auditoria
  INSERT INTO public.user_audit_log (user_id, action, new_data, performed_by)
  VALUES (
    target_user_id,
    'PASSWORD_CHANGE',
    jsonb_build_object(
      'changed_by_admin', current_user_role = 'admin' AND current_user_id != target_user_id,
      'timestamp', now()
    ),
    current_user_id
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Senha alterada com sucesso!',
    'user_email', target_user_email
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erro ao alterar senha: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Função para obter estatísticas de usuários (melhorada)
CREATE OR REPLACE FUNCTION public.get_user_statistics()
RETURNS JSONB AS $$
DECLARE
  current_user_role TEXT;
  stats JSONB;
BEGIN
  -- Verificar permissões
  SELECT role INTO current_user_role 
  FROM public.profiles 
  WHERE id = auth.uid();
  
  IF current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Apenas administradores podem ver estatísticas';
  END IF;
  
  -- Calcular estatísticas
  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(*) FROM public.profiles),
    'admins', (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin'),
    'managers', (SELECT COUNT(*) FROM public.profiles WHERE role = 'manager'),
    'regular_users', (SELECT COUNT(*) FROM public.profiles WHERE role = 'user'),
    'users_created_today', (
      SELECT COUNT(*) FROM public.profiles 
      WHERE DATE(created_at) = CURRENT_DATE
    ),
    'users_created_this_week', (
      SELECT COUNT(*) FROM public.profiles 
      WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)
    ),
    'users_created_this_month', (
      SELECT COUNT(*) FROM public.profiles 
      WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
    ),
    'last_updated', now()
  ) INTO stats;
  
  RETURN jsonb_build_object(
    'success', true,
    'data', stats
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erro ao obter estatísticas: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Conceder permissões
GRANT EXECUTE ON FUNCTION public.update_user_profile(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_password(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_statistics() TO authenticated;

-- 5. Comentários para documentação
COMMENT ON FUNCTION public.update_user_profile(UUID, TEXT, TEXT, TEXT) IS 'Atualiza perfil de usuário com validação e auditoria';
COMMENT ON FUNCTION public.update_user_password(UUID, TEXT, TEXT) IS 'Altera senha de usuário com validação e auditoria';
COMMENT ON FUNCTION public.get_user_statistics() IS 'Obtém estatísticas detalhadas de usuários (apenas admins)';