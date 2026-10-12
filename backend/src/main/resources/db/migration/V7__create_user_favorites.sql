-- Reconstructed from the existing development database's legacy V7 schema.
-- Idempotent for databases where this table was created before the source was retained.
CREATE TABLE IF NOT EXISTS user_favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    listing_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_favorites_user_listing UNIQUE (user_id, listing_id),
    CONSTRAINT fk_user_favorites_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_favorites_listing FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_listing_id ON user_favorites(listing_id);
