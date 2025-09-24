-- Verificação de usuários e possíveis conflitos de permissões
-- Este script ajuda a identificar duplicações e problemas de autenticação

-- 1. Verificar todos os usuários na tabela auth.users (Supabase Auth)
SELECT 
    'auth.users' as source,
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at,
    raw_user_meta_data,
    role as auth_role
FROM auth.users
ORDER BY created_at DESC;

-- 2. Verificar todos os profiles na tabela profiles
SELECT 
    'profiles' as source,
    id,
    name,
    email,
    role as profile_role,
    created_at,
    updated_at
FROM profiles
ORDER BY created_at DESC;

-- 3. Verificar usuários que existem em auth.users mas não têm profile
SELECT 
    'missing_profile' as issue,
    au.id,
    au.email,
    au.created_at as auth_created_at
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- 4. Verificar profiles que não têm usuário correspondente em auth.users
SELECT 
    'orphaned_profile' as issue,
    p.id,
    p.email,
    p.name,
    p.role,
    p.created_at as profile_created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE au.id IS NULL;

-- 5. Verificar duplicações por email
SELECT 
    'duplicate_emails' as issue,
    email,
    COUNT(*) as count
FROM (
    SELECT email FROM auth.users
    UNION ALL
    SELECT email FROM profiles
) combined
GROUP BY email
HAVING COUNT(*) > 2;

-- 6. Verificar usuários administradores
SELECT 
    'admin_users' as type,
    p.id,
    p.name,
    p.email,
    p.role,
    au.email_confirmed_at,
    au.last_sign_in_at,
    p.created_at as profile_created,
    au.created_at as auth_created
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'admin'
ORDER BY p.created_at DESC;

-- 7. Verificar se há múltiplos administradores
SELECT 
    'admin_count' as info,
    COUNT(*) as total_admins
FROM profiles
WHERE role = 'admin';

-- 8. Verificar logs de auditoria para o usuário atual (se existir)
SELECT 
    'audit_logs' as type,
    user_id,
    action,
    table_name,
    old_data,
    new_data,
    created_at
FROM audit_logs
WHERE user_id IN (
    SELECT id FROM profiles WHERE role = 'admin'
)
ORDER BY created_at DESC
LIMIT 20;