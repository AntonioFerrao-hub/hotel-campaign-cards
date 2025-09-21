-- Create storage bucket for campaign images
INSERT INTO storage.buckets (id, name, public) VALUES ('campaign-images', 'campaign-images', true);

-- Create policies for campaign image uploads
CREATE POLICY "Campaign images are publicly accessible" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'campaign-images');

CREATE POLICY "Authenticated users can upload campaign images" 
ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'campaign-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update campaign images" 
ON storage.objects 
FOR UPDATE 
USING (bucket_id = 'campaign-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete campaign images" 
ON storage.objects 
FOR DELETE 
USING (bucket_id = 'campaign-images' AND auth.role() = 'authenticated');