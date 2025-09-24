-- ========================================
-- CORREÇÃO DA CONSTRAINT user_audit_log_user_id_fkey
-- ========================================
-- Adiciona ON DELETE CASCADE para permitir deleção de usuários
-- que possuem registros na tabela user_audit_log

-- Remover constraint existente se existir
ALTER TABLE IF EXISTS public.user_audit_log 
DROP CONSTRAINT IF EXISTS user_audit_log_user_id_fkey;

-- Criar tabela user_audit_log se não existir
CREATE TABLE IF NOT EXISTS public.user_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    action TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    performed_by UUID,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recriar constraint com ON DELETE CASCADE
ALTER TABLE public.user_audit_log 
ADD CONSTRAINT user_audit_log_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

-- Adicionar constraint para performed_by com ON DELETE SET NULL
ALTER TABLE public.user_audit_log 
DROP CONSTRAINT IF EXISTS user_audit_log_performed_by_fkey;

ALTER TABLE public.user_audit_log 
ADD CONSTRAINT user_audit_log_performed_by_fkey 
FOREIGN KEY (performed_by) 
REFERENCES public.profiles(id) 
ON DELETE SET NULL;

-- Habilitar RLS se não estiver habilitado
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

-- Comentário para documentar a correção
COMMENT ON CONSTRAINT user_audit_log_user_id_fkey ON public.user_audit_log IS 
'Foreign key constraint with ON DELETE CASCADE to allow user deletion when audit logs exist';