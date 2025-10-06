-- =====================================================
-- VERIFICAR SE A TABELA CAMPAIGN_CATEGORIES FOI CRIADA
-- =====================================================
-- Execute este script no Supabase Dashboard > SQL Editor
-- para verificar se a tabela foi criada corretamente

-- 1. Verificar se a tabela existe
SELECT 
  table_name,
  table_schema
FROM information_schema.tables 
WHERE table_name = 'campaign_categories' 
  AND table_schema = 'public';

-- 2. Verificar estrutura da tabela
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'campaign_categories' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Verificar chaves estrangeiras
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'campaign_categories';

-- 4. Verificar índices
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'campaign_categories'
  AND schemaname = 'public';

-- 5. Verificar políticas RLS
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'campaign_categories'
  AND schemaname = 'public';

-- 6. Contar registros na tabela
SELECT 
  COUNT(*) as total_records
FROM public.campaign_categories;

-- 7. Mostrar alguns registros de exemplo
SELECT 
  cc.id,
  c.title as campaign_title,
  cat.name as category_name,
  cc.created_at
FROM public.campaign_categories cc
JOIN public.campaigns c ON cc.campaign_id = c.id
JOIN public.categories cat ON cc.category_id = cat.id
LIMIT 10;