-- Add display_order field to categories table for custom ordering
ALTER TABLE public.categories 
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- Create index for better performance when ordering
CREATE INDEX IF NOT EXISTS idx_categories_display_order ON public.categories(display_order);

-- Update existing categories with default order values
-- "Todos" should be first (order 0), others get incremental values
UPDATE public.categories 
SET display_order = CASE 
  WHEN name = 'Todos' THEN 0
  WHEN name = 'Temporada' THEN 1
  WHEN name = 'Promocional' THEN 2
  WHEN name = 'Gastronômico' THEN 3
  WHEN name = 'Familiar' THEN 4
  WHEN name = 'Romântico' THEN 5
  ELSE (
    SELECT COALESCE(MAX(display_order), 0) + 1 
    FROM public.categories c2 
    WHERE c2.id != categories.id
  )
END
WHERE display_order = 0;

-- Add comment for documentation
COMMENT ON COLUMN public.categories.display_order IS 'Custom order for displaying categories in the gallery. Lower values appear first.';