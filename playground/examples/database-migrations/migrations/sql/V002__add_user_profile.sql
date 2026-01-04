-- V002__add_user_profile.sql
-- Add profile information to users

ALTER TABLE users ADD COLUMN first_name VARCHAR(50);
ALTER TABLE users ADD COLUMN last_name VARCHAR(50);
ALTER TABLE users ADD COLUMN avatar_url TEXT;
ALTER TABLE users ADD COLUMN bio TEXT;

-- Add profile completion status
ALTER TABLE users ADD COLUMN profile_complete BOOLEAN DEFAULT FALSE;
