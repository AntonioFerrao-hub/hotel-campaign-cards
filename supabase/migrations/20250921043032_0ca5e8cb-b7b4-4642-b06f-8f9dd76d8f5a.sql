-- Adicionar campo para link de reserva
ALTER TABLE public.campaigns 
ADD COLUMN booking_url TEXT;