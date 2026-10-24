-- Keep existing leases and IDs. New contracts are drafts until tenant acceptance.
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS note VARCHAR(2000);
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS listing_title VARCHAR(255);
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS listing_address VARCHAR(255);
UPDATE contracts c SET listing_title=l.title, listing_address=l.address FROM listings l
    WHERE l.listing_id=c.listing_id AND c.listing_title IS NULL;
ALTER TABLE contracts DROP CONSTRAINT IF EXISTS contracts_status_check;
ALTER TABLE contracts ADD CONSTRAINT contracts_status_check
    CHECK (status IN ('DRAFT','ACTIVE','EXPIRED','TERMINATED','CANCELLED'));
ALTER TABLE contracts ALTER COLUMN status SET DEFAULT 'DRAFT';
ALTER TABLE contracts ADD CONSTRAINT contracts_dates_check CHECK (end_date > start_date) NOT VALID;
ALTER TABLE contracts ADD CONSTRAINT contracts_money_check CHECK (monthly_rent > 0 AND deposit_amount >= 0) NOT VALID;
CREATE INDEX IF NOT EXISTS idx_contracts_listing_status ON contracts(listing_id, status);
