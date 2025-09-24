-- ========================================
-- EXECUTE ESTE SCRIPT NO SUPABASE DASHBOARD
-- ========================================
-- Vá para: https://supabase.com/dashboard/project/[SEU_PROJECT_ID]/sql
-- Cole este código e execute para corrigir o erro de exclusão de usuários

-- PASSO 1: Remover constraint existente que está causando o problema
ALTER TABLE IF EXISTS public.user_audit_log 
DROP CONSTRAINT IF EXISTS user_audit_log_user_id_fkey;

-- PASSO 2: Verificar se a tabela user_audit_log existe, se não, criar
CREATE TABLE IF NOT EXISTS public.user_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    action TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    performed_by UUID,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PASSO 3: Recriar constraint com ON DELETE CASCADE (SOLUÇÃO DO PROBLEMA)
ALTER TABLE public.user_audit_log 
ADD CONSTRAINT user_audit_log_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

-- PASSO 4: Adicionar constraint para performed_by com ON DELETE SET NULL
ALTER TABLE public.user_audit_log 
DROP CONSTRAINT IF EXISTS user_audit_log_performed_by_fkey;

ALTER TABLE public.user_audit_log 
ADD CONSTRAINT user_audit_log_performed_by_fkey 
FOREIGN KEY (performed_by) 
REFERENCES public.profiles(id) 
ON DELETE SET NULL;

-- PASSO 5: Configurar RLS e políticas
ALTER TABLE public.user_audit_log ENABLE ROW LEVEL SECURITY;

-- Remover políticas existentes
DROP POLICY IF EXISTS "Admins can view all audit logs" ON public.user_audit_log;
DROP POLICY IF EXISTS "System can insert audit logs" ON public.user_audit_log;

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

-- PASSO 6: Verificar se a correção foi aplicada
SELECT 
    'CORREÇÃO APLICADA COM SUCESSO!' as status,
    tc.constraint_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_name = 'user_audit_log_user_id_fkey'
    AND tc.table_name = 'user_audit_log'
    AND tc.table_schema = 'public';

-- Se você ver "CASCADE" na coluna delete_rule, a correção foi aplicada com sucesso!