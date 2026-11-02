CREATE INDEX IF NOT EXISTS idx_listings_available_geography
ON listings USING GIST ((CAST(location AS geography)))
WHERE location IS NOT NULL AND approval_status = 'APPROVED' AND rental_status = 'AVAILABLE';
