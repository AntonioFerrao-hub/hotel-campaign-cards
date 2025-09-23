-- ========================================
-- CRIAR FUNÇÃO GET_USERS PARA PROFILES
-- ========================================

-- Função para listar usuários da tabela profiles
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
    true as active, -- Assumir que todos os usuários estão ativos por padrão
    NULL::TIMESTAMPTZ as last_login, -- Campo não existe na tabela atual
    p.created_at,
    p.updated_at
  FROM public.profiles p
  ORDER BY p.created_at DESC;
END;
$$;

-- Conceder permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION public.get_users() TO authenticated;

-- ========================================
-- FUNÇÃO ADICIONAL: GET_ALL_USERS (INCLUINDO INATIVOS)
-- ========================================

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
    true as active, -- Assumir que todos os usuários estão ativos por padrão
    NULL::TIMESTAMPTZ as last_login, -- Campo não existe na tabela atual
    p.created_at,
    p.updated_at
  FROM public.profiles p
  ORDER BY p.created_at DESC;
END;
$$;

-- Conceder permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION public.get_all_users() TO authenticated;