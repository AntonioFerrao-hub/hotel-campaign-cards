-- Add image_url column to campaigns table
ALTER TABLE public.campaigns 
ADD COLUMN image_url TEXT;