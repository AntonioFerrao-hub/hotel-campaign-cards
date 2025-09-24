-- VALIDAÇÃO E LISTAGEM DE USUÁRIOS - Execute no Supabase SQL Editor
-- Este script valida e lista todos os perfis disponíveis no projeto

-- 1. Verificar se a tabela profiles existe e sua estrutura
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Listar todos os usuários/perfis existentes
SELECT 
    id as user_id,
    name as user_name,
    email as user_email,
    role as user_role,
    created_at,
    updated_at,
    CASE 
        WHEN role = 'admin' THEN '🔑 Administrador'
        WHEN role = 'user' THEN '👤 Usuário'
        ELSE '❓ Função Desconhecida'
    END as role_description
FROM public.profiles 
ORDER BY 
    CASE role 
        WHEN 'admin' THEN 1 
        WHEN 'user' THEN 2 
        ELSE 3 
    END,
    created_at DESC;

-- 3. Estatísticas dos perfis
SELECT 
    'Total de Perfis' as metric,
    COUNT(*)::text as value
FROM public.profiles
UNION ALL
SELECT 
    'Administradores' as metric,
    COUNT(*)::text as value
FROM public.profiles 
WHERE role = 'admin'
UNION ALL
SELECT 
    'Usuários Regulares' as metric,
    COUNT(*)::text as value
FROM public.profiles 
WHERE role = 'user'
UNION ALL
SELECT 
    'Outros Papéis' as metric,
    COUNT(*)::text as value
FROM public.profiles 
WHERE role NOT IN ('admin', 'user');

-- 4. Verificar funções RPC disponíveis relacionadas a usuários
SELECT 
    routine_name as function_name,
    routine_type,
    data_type as return_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%user%' 
OR routine_name LIKE '%profile%'
ORDER BY routine_name;

-- 5. Verificar políticas RLS na tabela profiles
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'profiles';

-- 6. Testar função de listagem (se existir)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name = 'list_all_profiles'
    ) THEN
        RAISE NOTICE 'Função list_all_profiles encontrada - testando...';
        -- A função será testada separadamente
    ELSE
        RAISE NOTICE 'Função list_all_profiles NÃO encontrada';
    END IF;
END $$;

-- 7. Verificar se há usuários autenticados no auth.users
SELECT 
    'Usuários no Auth' as info,
    COUNT(*)::text as count
FROM auth.users;

-- 8. Verificar correspondência entre auth.users e profiles
SELECT 
    'Usuários Auth com Profile' as info,
    COUNT(*)::text as count
FROM auth.users au
INNER JOIN public.profiles p ON au.id = p.id;

SELECT 
    'Usuários Auth sem Profile' as info,
    COUNT(*)::text as count
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;