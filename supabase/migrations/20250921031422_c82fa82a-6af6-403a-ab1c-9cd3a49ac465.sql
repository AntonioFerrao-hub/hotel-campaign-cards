-- Remove foreign key constraint from campaigns table to make hotel_id optional
ALTER TABLE campaigns DROP CONSTRAINT IF EXISTS campaigns_hotel_id_fkey;

-- Make hotel_id nullable
ALTER TABLE campaigns ALTER COLUMN hotel_id DROP NOT NULL;

-- Set default value for hotel_id
ALTER TABLE campaigns ALTER COLUMN hotel_id SET DEFAULT null;