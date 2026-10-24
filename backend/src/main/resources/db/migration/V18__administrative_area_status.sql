ALTER TABLE administrative_areas ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
CREATE INDEX idx_areas_parent_active ON administrative_areas(parent_id, is_active);
