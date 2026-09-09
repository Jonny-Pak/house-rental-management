CREATE TABLE properties (
    id BIGSERIAL PRIMARY KEY,
    landlord_id BIGINT NOT NULL REFERENCES users(user_id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(255) NOT NULL,
    province_id BIGINT NOT NULL REFERENCES administrative_areas(area_id),
    district_id BIGINT NOT NULL REFERENCES administrative_areas(area_id),
    ward_id BIGINT NOT NULL REFERENCES administrative_areas(area_id),
    electricity_price DECIMAL(10,2),
    water_price DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_properties_landlord_id ON properties(landlord_id);
