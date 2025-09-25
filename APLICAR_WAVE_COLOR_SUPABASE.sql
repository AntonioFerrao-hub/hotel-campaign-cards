-- ========================================
-- APLICAR NO SUPABASE DASHBOARD
-- ========================================
-- Este arquivo deve ser executado no SQL Editor do Supabase Dashboard
-- para adicionar o campo wave_color à tabela campaigns

-- Adicionar campo wave_color à tabela campaigns
ALTER TABLE public.campaigns 
ADD COLUMN IF NOT EXISTS wave_color TEXT DEFAULT '#3B82F6';

-- Adicionar comentário para documentar o campo
COMMENT ON COLUMN public.campaigns.wave_color IS 'Cor personalizada da onda em formato hexadecimal (ex: #3B82F6)';

-- Verificar se a coluna foi criada com sucesso
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'campaigns' 
AND column_name = 'wave_color';

-- Opcional: Atualizar campanhas existentes com uma cor padrão
-- UPDATE public.campaigns SET wave_color = '#3B82F6' WHERE wave_color IS NULL;