-- Remover políticas restritivas de categorias e permitir acesso público para CRUD
DROP POLICY IF EXISTS "Admins can manage all categories" ON public.categories;

-- Criar políticas públicas para categorias (similar às campanhas)
CREATE POLICY "Allow public insert access to categories" 
ON public.categories 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Allow public update access to categories" 
ON public.categories 
FOR UPDATE 
USING (true);

CREATE POLICY "Allow public delete access to categories" 
ON public.categories 
FOR DELETE 
USING (true);