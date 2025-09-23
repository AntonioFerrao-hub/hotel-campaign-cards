-- ========================================
-- CRIAR FUNÇÃO TOGGLE_USER_STATUS
-- ========================================

-- Como a tabela profiles não tem coluna 'active', vamos simular o comportamento
-- usando uma abordagem alternativa: marcar usuários como inativos alterando o role
-- ou criar uma tabela separada para controlar status

-- Opção 1: Criar tabela para controlar status de usuários
CREATE TABLE IF NOT EXISTS public.user_status (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  active BOOLEAN DEFAULT true,
  deactivated_at TIMESTAMPTZ,
  deactivated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS na tabela user_status
ALTER TABLE public.user_status ENABLE ROW LEVEL SECURITY;

-- Política para permitir que admins vejam e modifiquem status
CREATE POLICY "Admins can manage user status" ON public.user_status
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Função para alternar status do usuário
CREATE OR REPLACE FUNCTION public.toggle_user_status(user_id UUID)
RETURNS JSONB AS $$
DECLARE
  current_user_role TEXT;
  current_user_id UUID;
  target_user_name TEXT;
  current_status BOOLEAN;
  new_status BOOLEAN;
BEGIN
  current_user_id := auth.uid();
  
  -- Verificar se usuário está autenticado
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;
  
  -- Verificar se o usuário atual é admin
  SELECT role INTO current_user_role 
  FROM public.profiles 
  WHERE id = current_user_id;
  
  IF current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Apenas administradores podem alterar status de usuários';
  END IF;
  
  -- Verificar se usuário alvo existe
  SELECT name INTO target_user_name
  FROM public.profiles 
  WHERE id = user_id;
  
  IF target_user_name IS NULL THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;
  
  -- Não permitir que admin desative a si mesmo
  IF user_id = current_user_id THEN
    RAISE EXCEPTION 'Você não pode desativar sua própria conta';
  END IF;
  
  -- Verificar status atual (padrão é ativo se não existir registro)
  SELECT COALESCE(active, true) INTO current_status
  FROM public.user_status 
  WHERE user_status.user_id = toggle_user_status.user_id;
  
  -- Se não existe registro, criar um
  IF NOT FOUND THEN
    current_status := true;
    INSERT INTO public.user_status (user_id, active)
    VALUES (user_id, true);
  END IF;
  
  -- Alternar status
  new_status := NOT current_status;
  
  -- Atualizar status
  INSERT INTO public.user_status (user_id, active, deactivated_at, deactivated_by, updated_at)
  VALUES (
    user_id, 
    new_status,
    CASE WHEN new_status = false THEN NOW() ELSE NULL END,
    CASE WHEN new_status = false THEN current_user_id ELSE NULL END,
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    active = EXCLUDED.active,
    deactivated_at = EXCLUDED.deactivated_at,
    deactivated_by = EXCLUDED.deactivated_by,
    updated_at = EXCLUDED.updated_at;
  
  -- Log da auditoria (se a tabela existir)
  BEGIN
    INSERT INTO public.user_audit_log (user_id, action, old_data, new_data, performed_by)
    VALUES (
      user_id,
      CASE WHEN new_status THEN 'USER_ACTIVATED' ELSE 'USER_DEACTIVATED' END,
      jsonb_build_object('active', current_status),
      jsonb_build_object('active', new_status),
      current_user_id
    );
  EXCEPTION
    WHEN undefined_table THEN
      -- Ignorar se tabela de auditoria não existir
      NULL;
  END;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', CASE 
      WHEN new_status THEN 'Usuário ativado com sucesso'
      ELSE 'Usuário desativado com sucesso'
    END,
    'user_name', target_user_name,
    'previous_status', current_status,
    'new_status', new_status
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erro ao alterar status: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Conceder permissões
GRANT EXECUTE ON FUNCTION public.toggle_user_status(UUID) TO authenticated;

-- ========================================
-- ATUALIZAR FUNÇÃO GET_USERS PARA INCLUIR STATUS
-- ========================================

-- Atualizar função get_users para incluir status real
CREATE OR REPLACE FUNCTION public.get_users()
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
  SELECT 
    p.id,
    p.email,
    p.name,
    COALESCE(p.role, 'user') as role,
    COALESCE(us.active, true) as active, -- Status real da tabela user_status
    NULL::TIMESTAMPTZ as last_login, -- Campo não existe na tabela atual
    p.created_at,
    p.updated_at
  FROM public.profiles p
  LEFT JOIN public.user_status us ON us.user_id = p.id
  ORDER BY p.created_at DESC;
END;
$$;

-- Atualizar função get_all_users para incluir status real
CREATE OR REPLACE FUNCTION public.get_all_users()
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
  SELECT 
    p.id,
    p.email,
    p.name,
    COALESCE(p.role, 'user') as role,
    COALESCE(us.active, true) as active, -- Status real da tabela user_status
    NULL::TIMESTAMPTZ as last_login, -- Campo não existe na tabela atual
    p.created_at,
    p.updated_at
  FROM public.profiles p
  LEFT JOIN public.user_status us ON us.user_id = p.id
  ORDER BY p.created_at DESC;
END;
$$;

-- ========================================
-- COMENTÁRIOS E INSTRUÇÕES
-- ========================================

/*
INSTRUÇÕES DE USO:

1. Execute este script completo no Supabase Dashboard
2. Isso criará:
   - Tabela user_status para controlar status ativo/inativo
   - Função toggle_user_status para alternar status
   - Atualizará as funções get_users para incluir status real

3. Após executar, teste no UserManagement:
   - Listar usuários deve funcionar
   - Alternar status deve funcionar
   - Status deve ser persistido corretamente

ESTRUTURA CRIADA:
- public.user_status: controla se usuário está ativo/inativo
- public.toggle_user_status(user_id): alterna status do usuário
- Funções get_users atualizadas para mostrar status real
*/