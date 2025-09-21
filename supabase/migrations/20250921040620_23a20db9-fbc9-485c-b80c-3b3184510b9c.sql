-- Adicionar campos necessários para o layout dos cards
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS price_label TEXT DEFAULT 'A partir de';
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS duration_nights INTEGER DEFAULT 2;