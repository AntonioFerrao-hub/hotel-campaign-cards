-- Adicionar campo category à tabela campaigns
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS category TEXT;