-- V3: Add parent_id and code to administrative_areas for Province/District/Ward hierarchy
ALTER TABLE administrative_areas ADD COLUMN IF NOT EXISTS code VARCHAR(20);
ALTER TABLE administrative_areas ADD COLUMN IF NOT EXISTS parent_id BIGINT REFERENCES administrative_areas(area_id);
CREATE INDEX IF NOT EXISTS idx_areas_parent_id ON administrative_areas(parent_id);
CREATE INDEX IF NOT EXISTS idx_areas_type ON administrative_areas(area_type);
