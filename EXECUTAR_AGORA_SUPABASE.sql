-- =====================================================
-- EXECUTAR IMEDIATAMENTE NO SUPABASE SQL EDITOR
-- =====================================================
-- Cole este código completo no Supabase SQL Editor e clique em RUN

-- 1. Criar tabela campaign_categories
CREATE TABLE IF NOT EXISTS public.campaign_categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(campaign_id, category_id)
);

-- 2. Habilitar RLS
ALTER TABLE public.campaign_categories ENABLE ROW LEVEL SECURITY;

-- 3. Criar políticas de acesso
CREATE POLICY "Allow public read access to campaign_categories" 
ON public.campaign_categories FOR SELECT USING (true);

CREATE POLICY "Allow public insert access to campaign_categories" 
ON public.campaign_categories FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public update access to campaign_categories" 
ON public.campaign_categories FOR UPDATE USING (true);

CREATE POLICY "Allow public delete access to campaign_categories" 
ON public.campaign_categories FOR DELETE USING (true);

-- 4. Criar índices
CREATE INDEX IF NOT EXISTS idx_campaign_categories_campaign_id ON public.campaign_categories(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_categories_category_id ON public.campaign_categories(category_id);

-- 5. Migrar dados existentes
INSERT INTO public.campaign_categories (campaign_id, category_id)
SELECT 
  c.id as campaign_id,
  cat.id as category_id
FROM public.campaigns c
JOIN public.categories cat ON cat.name = c.category
WHERE c.category IS NOT NULL 
  AND c.category != ''
  AND NOT EXISTS (
    SELECT 1 FROM public.campaign_categories cc 
    WHERE cc.campaign_id = c.id AND cc.category_id = cat.id
  );

-- 6. Verificar se funcionou
SELECT 'Tabela criada com sucesso!' as status, COUNT(*) as registros_migrados
FROM public.campaign_categories;