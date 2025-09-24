-- Fix user creation permissions by adding specific INSERT policy for profiles table

-- Drop the existing "Admins can manage all profiles" policy to recreate it more specifically
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

-- Create separate policies for different operations
CREATE POLICY "Admins can insert profiles" 
ON public.profiles 
FOR INSERT 
WITH CHECK (true); -- Allow INSERT for the create_user_with_password function

CREATE POLICY "Admins can update profiles" 
ON public.profiles 
FOR UPDATE 
USING (get_current_user_role() = 'admin');

CREATE POLICY "Admins can delete profiles" 
ON public.profiles 
FOR DELETE 
USING (get_current_user_role() = 'admin');

-- Grant necessary permissions to the create_user_with_password function
GRANT INSERT ON public.profiles TO authenticated;
GRANT INSERT ON auth.users TO authenticated;

-- Ensure the create_user_with_password function can bypass RLS when needed
ALTER FUNCTION public.create_user_with_password(TEXT, TEXT, TEXT, TEXT, TEXT[]) SECURITY DEFINER;