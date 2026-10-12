-- Keep listings referenced by contracts when their owner removes them.
ALTER TABLE listings DROP CONSTRAINT IF EXISTS listings_rental_status_check;
ALTER TABLE listings ADD CONSTRAINT listings_rental_status_check
    CHECK (rental_status IN ('AVAILABLE', 'RENTED', 'HIDDEN', 'DELETED'));
CREATE INDEX IF NOT EXISTS idx_listings_owner_created ON listings(owner_id, created_at DESC);
