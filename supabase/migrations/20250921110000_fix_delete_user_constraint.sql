-- ========================================
-- CORREÇÃO DA FUNÇÃO DELETE_USER_PROFILE
-- ========================================
-- Problema: A função estava tentando inserir log de auditoria APÓS deletar o usuário,
-- causando violação da constraint de chave estrangeira user_audit_log_user_id_fkey

CREATE OR REPLACE FUNCTION public.delete_user_profile(
  target_user_id UUID,
  confirmation_email TEXT,
  permanent_delete BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
  current_user_role TEXT;
  current_user_id UUID;
  target_user_data JSONB;
  target_email TEXT;
BEGIN
  current_user_id := auth.uid();
  
  -- Verificar permissões (apenas admins podem deletar)
  SELECT role INTO current_user_role 
  FROM public.profiles 
  WHERE id = current_user_id;
  
  IF current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Apenas administradores podem excluir usuários';
  END IF;
  
  -- Verificar se usuário existe e obter dados
  SELECT email INTO target_email
  FROM public.profiles 
  WHERE id = target_user_id;
  
  IF target_email IS NULL THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;
  
  -- Verificar confirmação por email
  IF target_email != confirmation_email THEN
    RAISE EXCEPTION 'Email de confirmação não confere';
  END IF;
  
  -- Não permitir auto-exclusão
  IF current_user_id = target_user_id THEN
    RAISE EXCEPTION 'Não é possível excluir seu próprio usuário';
  END IF;
  
  -- Capturar dados antes da exclusão
  SELECT jsonb_build_object(
    'id', id,
    'name', name,
    'email', email,
    'role', role
  ) INTO target_user_data
  FROM public.profiles 
  WHERE id = target_user_id;
  
  IF permanent_delete THEN
    -- CORREÇÃO: Inserir log de auditoria ANTES de deletar o usuário
    INSERT INTO public.user_audit_log (user_id, action, old_data, performed_by)
    VALUES (
      target_user_id,
      'DELETE_PERMANENT',
      target_user_data,
      current_user_id
    );
    
    -- Exclusão física (permanente)
    DELETE FROM public.profiles WHERE id = target_user_id;
    
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Usuário excluído permanentemente!',
      'deleted_user', target_user_data
    );
  ELSE
    -- CORREÇÃO: Inserir log de auditoria ANTES de deletar o usuário
    INSERT INTO public.user_audit_log (user_id, action, old_data, performed_by)
    VALUES (
      target_user_id,
      'DELETE',
      target_user_data,
      current_user_id
    );
    
    -- Exclusão lógica (adicionar campo deleted_at se não existir)
    -- Por enquanto, fazemos exclusão física já que não temos campo deleted_at
    DELETE FROM public.profiles WHERE id = target_user_id;
    
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Usuário excluído com sucesso!',
      'deleted_user', target_user_data
    );
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erro ao excluir usuário: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentário sobre a função
COMMENT ON FUNCTION public.delete_user_profile(UUID, TEXT, BOOLEAN) IS 'Exclui usuário com validação e auditoria (log inserido ANTES da exclusão)';