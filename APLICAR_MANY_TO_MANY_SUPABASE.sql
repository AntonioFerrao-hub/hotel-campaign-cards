-- =====================================================
-- APLICAR RELACIONAMENTO MANY-TO-MANY NO SUPABASE
-- =====================================================
-- Execute este script no Supabase Dashboard > SQL Editor
-- URL: https://mpdblvvznqpajascuxxb.supabase.co/project/mpdblvvznqpajascuxxb/sql

-- 1. Criar tabela de junção para relacionamento many-to-many
CREATE TABLE IF NOT EXISTS public.campaign_categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(campaign_id, category_id)
);

-- 2. Habilitar Row Level Security
ALTER TABLE public.campaign_categories ENABLE ROW LEVEL SECURITY;

-- 3. Criar políticas de acesso público (similar às outras tabelas)
CREATE POLICY "Allow public read access to campaign_categories" 
ON public.campaign_categories 
FOR SELECT 
USING (true);

CREATE POLICY "Allow public insert access to campaign_categories" 
ON public.campaign_categories 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Allow public update access to campaign_categories" 
ON public.campaign_categories 
FOR UPDATE 
USING (true);

CREATE POLICY "Allow public delete access to campaign_categories" 
ON public.campaign_categories 
FOR DELETE 
USING (true);

-- 4. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_campaign_categories_campaign_id ON public.campaign_categories(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_categories_category_id ON public.campaign_categories(category_id);

-- 5. Migrar dados existentes (categoria única para múltiplas categorias)
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

-- 6. Verificar se tudo foi criado corretamente
SELECT 
  'campaign_categories table created' as status,
  COUNT(*) as total_records
FROM public.campaign_categories;

-- 7. Mostrar relacionamentos existentes
SELECT 
  c.title as campaign_title,
  cat.name as category_name
FROM public.campaigns c
JOIN public.campaign_categories cc ON c.id = cc.campaign_id
JOIN public.categories cat ON cc.category_id = cat.id
ORDER BY c.title, cat.name;

-- =====================================================
-- INSTRUÇÕES:
-- 1. Copie todo este código
-- 2. Cole no Supabase SQL Editor
-- 3. Clique em "Run" para executar
-- 4. Verifique se não há erros
-- 5. Confirme que os dados foram migrados corretamente
-- =====================================================