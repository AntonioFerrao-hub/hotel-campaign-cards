-- Create junction table for many-to-many relationship between campaigns and categories
CREATE TABLE IF NOT EXISTS public.campaign_categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(campaign_id, category_id)
);

-- Enable Row Level Security
ALTER TABLE public.campaign_categories ENABLE ROW LEVEL SECURITY;

-- Create policies for campaign_categories (public access like other tables)
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_campaign_categories_campaign_id ON public.campaign_categories(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_categories_category_id ON public.campaign_categories(category_id);

-- Migrate existing single category data to many-to-many structure
-- This will create entries in campaign_categories for existing campaigns with categories
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

-- Add comment for documentation
COMMENT ON TABLE public.campaign_categories IS 'Junction table for many-to-many relationship between campaigns and categories';