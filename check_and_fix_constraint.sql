-- ========================================
-- VERIFICAR E CORRIGIR CONSTRAINT DE CHAVE ESTRANGEIRA
-- ========================================
-- Execute este script no Supabase Dashboard para corrigir o problema de deleção

-- 1. Verificar se a tabela user_audit_log existe
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'user_audit_log' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Verificar constraints existentes
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
LEFT JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
    AND tc.table_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'user_audit_log'
    AND tc.table_schema = 'public';

-- 3. Se a constraint existe sem CASCADE, removê-la e recriar com CASCADE
DO $$
BEGIN
    -- Verificar se a constraint existe
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_audit_log_user_id_fkey'
            AND table_name = 'user_audit_log'
            AND table_schema = 'public'
    ) THEN
        -- Remover constraint existente
        ALTER TABLE public.user_audit_log 
        DROP CONSTRAINT IF EXISTS user_audit_log_user_id_fkey;
        
        RAISE NOTICE 'Constraint user_audit_log_user_id_fkey removida';
    END IF;
    
    -- Verificar se a tabela user_audit_log existe
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_name = 'user_audit_log' 
            AND table_schema = 'public'
    ) THEN
        -- Recriar constraint com ON DELETE CASCADE
        ALTER TABLE public.user_audit_log 
        ADD CONSTRAINT user_audit_log_user_id_fkey 
        FOREIGN KEY (user_id) 
        REFERENCES public.profiles(id) 
        ON DELETE CASCADE;
        
        RAISE NOTICE 'Constraint user_audit_log_user_id_fkey recriada com ON DELETE CASCADE';
    ELSE
        RAISE NOTICE 'Tabela user_audit_log não existe - criando...';
        
        -- Criar tabela user_audit_log se não existir
        CREATE TABLE IF NOT EXISTS public.user_audit_log (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL,
            action TEXT NOT NULL,
            old_data JSONB,
            new_data JSONB,
            performed_by UUID,
            performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            CONSTRAINT user_audit_log_user_id_fkey 
                FOREIGN KEY (user_id) 
                REFERENCES public.profiles(id) 
                ON DELETE CASCADE,
            CONSTRAINT user_audit_log_performed_by_fkey 
                FOREIGN KEY (performed_by) 
                REFERENCES public.profiles(id) 
                ON DELETE SET NULL
        );
        
        -- Habilitar RLS
        ALTER TABLE public.user_audit_log ENABLE ROW LEVEL SECURITY;
        
        -- Política para admins verem todos os logs
        CREATE POLICY "Admins can view all audit logs" ON public.user_audit_log
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() AND role = 'admin'
                )
            );
        
        -- Política para inserção de logs (sistema)
        CREATE POLICY "System can insert audit logs" ON public.user_audit_log
            FOR INSERT WITH CHECK (true);
        
        RAISE NOTICE 'Tabela user_audit_log criada com constraint ON DELETE CASCADE';
    END IF;
END $$;

-- 4. Verificar se a correção foi aplicada
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
LEFT JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
    AND tc.table_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'user_audit_log'
    AND tc.table_schema = 'public'
    AND tc.constraint_name = 'user_audit_log_user_id_fkey';