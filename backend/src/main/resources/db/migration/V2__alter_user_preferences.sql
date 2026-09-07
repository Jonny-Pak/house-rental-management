-- V2__alter_user_preferences.sql
ALTER TABLE user_preferences DROP COLUMN preference_group;
ALTER TABLE user_preferences DROP COLUMN preference_value;
ALTER TABLE user_preferences ADD COLUMN min_budget DOUBLE PRECISION;
ALTER TABLE user_preferences ADD COLUMN max_budget DOUBLE PRECISION;
ALTER TABLE user_preferences ADD COLUMN has_pet BOOLEAN;
ALTER TABLE user_preferences ADD COLUMN preferred_area VARCHAR(150);
ALTER TABLE user_preferences ADD CONSTRAINT uk_user_preferences_user_id UNIQUE (user_id);
