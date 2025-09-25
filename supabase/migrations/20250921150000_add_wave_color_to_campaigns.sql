-- Adicionar campo wave_color à tabela campaigns
-- Este campo armazenará a cor personalizada da onda em formato hexadecimal
ALTER TABLE public.campaigns 
ADD COLUMN IF NOT EXISTS wave_color TEXT DEFAULT '#3B82F6';

-- Adicionar comentário para documentar o campo
COMMENT ON COLUMN public.campaigns.wave_color IS 'Cor personalizada da onda em formato hexadecimal (ex: #3B82F6)';