CREATE TABLE favorite_properties (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    property_id BIGINT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_property UNIQUE (user_id, property_id)
);

CREATE INDEX idx_favorites_user_id     ON favorite_properties(user_id);
CREATE INDEX idx_favorites_property_id ON favorite_properties(property_id);
