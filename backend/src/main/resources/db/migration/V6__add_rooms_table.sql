CREATE TABLE rooms (
    id BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(id),
    name VARCHAR(255) NOT NULL,
    area DOUBLE PRECISION NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    max_capacity INT NOT NULL,
    status VARCHAR(50) DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rooms_property_id ON rooms(property_id);
