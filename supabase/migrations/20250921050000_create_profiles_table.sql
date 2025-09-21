-- Create profiles table for user management
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Profiles are viewable by authenticated users" 
ON public.profiles 
FOR SELECT 
USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage all profiles" 
ON public.profiles 
FOR ALL 
USING (get_current_user_role() = 'admin');

-- Create trigger for automatic timestamp updates
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to get current user role
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role
  FROM public.profiles
  WHERE id = auth.uid();
  
  RETURN COALESCE(user_role, 'user');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RPC functions for user management
CREATE OR REPLACE FUNCTION public.create_user_with_password(
  user_email TEXT,
  user_name TEXT,
  user_password TEXT,
  user_role TEXT DEFAULT 'user',
  user_hotel_ids TEXT[] DEFAULT '{}'
)
RETURNS TEXT AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Create auth user
  INSERT INTO auth.users (email, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (
    user_email,
    crypt(user_password, gen_salt('bf')),
    now(),
    now(),
    now()
  )
  RETURNING id INTO new_user_id;
  
  -- Create profile
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (new_user_id, user_name, user_email, user_role);
  
  RETURN new_user_id::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_user_profile(
  target_user_id TEXT,
  user_name TEXT,
  user_email TEXT,
  user_role TEXT,
  user_hotel_ids TEXT[]
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.profiles
  SET 
    name = user_name,
    email = user_email,
    role = user_role,
    updated_at = now()
  WHERE id = target_user_id::UUID;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.delete_user_profile(
  target_user_id TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Delete from profiles
  DELETE FROM public.profiles WHERE id = target_user_id::UUID;
  
  -- Delete from auth.users
  DELETE FROM auth.users WHERE id = target_user_id::UUID;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert a default admin user for testing
INSERT INTO public.profiles (id, name, email, role) VALUES
(gen_random_uuid(), 'Administrador', 'admin@hotel.com', 'admin');