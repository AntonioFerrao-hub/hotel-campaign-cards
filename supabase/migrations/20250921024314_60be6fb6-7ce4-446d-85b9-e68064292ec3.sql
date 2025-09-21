-- Temporarily allow public access to campaigns for testing
-- Remove existing policies
DROP POLICY IF EXISTS "Admins can view all campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Users can view campaigns for their assigned hotels" ON public.campaigns;
DROP POLICY IF EXISTS "Admins can insert campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Admins can update campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Admins can delete campaigns" ON public.campaigns;

-- Create temporary public policies for campaigns
CREATE POLICY "Allow public read access to campaigns" 
ON public.campaigns 
FOR SELECT 
USING (true);

CREATE POLICY "Allow public insert access to campaigns" 
ON public.campaigns 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Allow public update access to campaigns" 
ON public.campaigns 
FOR UPDATE 
USING (true);

CREATE POLICY "Allow public delete access to campaigns" 
ON public.campaigns 
FOR DELETE 
USING (true);

-- Create storage bucket policies for public access
CREATE POLICY "Allow public uploads to campaign-images" 
ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'campaign-images');

CREATE POLICY "Allow public access to campaign-images" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'campaign-images');