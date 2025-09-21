-- Create categories table
CREATE TABLE public.categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Create policies for categories
CREATE POLICY "Categories are publicly viewable" 
ON public.categories 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage all categories" 
ON public.categories 
FOR ALL 
USING (get_current_user_role() = 'admin');

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_categories_updated_at
BEFORE UPDATE ON public.categories
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Insert default categories
INSERT INTO public.categories (name, description) VALUES
('Temporada', 'Campanhas sazonais'),
('Promocional', 'Ofertas especiais'),
('Gastronômico', 'Experiências gastronômicas'),
('Familiar', 'Pacotes para famílias'),
('Romântico', 'Experiências românticas');