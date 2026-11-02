CREATE TABLE amenities (
    amenity_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(20) NOT NULL CHECK (category IN ('FURNITURE', 'UTILITY')),
    description VARCHAR(255) NOT NULL DEFAULT '',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    version BIGINT NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX idx_amenity_category_name ON amenities(category, lower(name));

CREATE TABLE listing_amenities (
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    amenity_id BIGINT NOT NULL REFERENCES amenities(amenity_id),
    PRIMARY KEY (listing_id, amenity_id)
);
CREATE INDEX idx_listing_amenities_amenity ON listing_amenities(amenity_id);

INSERT INTO amenities(name, category) VALUES
('Giường', 'FURNITURE'), ('Tủ quần áo', 'FURNITURE'),
('Bàn ghế', 'FURNITURE'), ('Máy lạnh', 'FURNITURE'),
('Tủ lạnh', 'FURNITURE'), ('Máy giặt', 'FURNITURE'),
('Bếp nấu ăn', 'FURNITURE'), ('Máy nước nóng', 'FURNITURE'),
('Wi-Fi', 'UTILITY'), ('Chỗ để xe', 'UTILITY'),
('Thang máy', 'UTILITY'), ('Ban công', 'UTILITY'),
('Nhà vệ sinh riêng', 'UTILITY'), ('Camera an ninh', 'UTILITY');
