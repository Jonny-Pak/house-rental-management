-- Khoi tao database moi. Quan ly cau truc bang SQL thu cong.
BEGIN;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = current_schema()
          AND table_name = 'users'
    ) THEN
        RAISE EXCEPTION 'Chi chay database.sql tren database/schema moi. Khong chay tren database dang dung.';
    END IF;
END $$;

-- init database
-- Bật extension PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Table users
CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone_number VARCHAR(15) UNIQUE,
    password_hash VARCHAR(255),
    google_id VARCHAR(100) UNIQUE,
    avatar_url VARCHAR(255),
    role VARCHAR(10) NOT NULL CHECK (role IN ('USER', 'OWNER', 'ADMIN')),
    status VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'LOCKED')),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- 2. Table user_preferences
CREATE TABLE user_preferences (
    preference_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    min_budget DOUBLE PRECISION,
    max_budget DOUBLE PRECISION,
    has_pet BOOLEAN,
    preferred_area VARCHAR(150)
);

-- 3. Table administrative_areas (PostGIS)
CREATE TABLE administrative_areas (
    area_id BIGSERIAL PRIMARY KEY,
    area_name VARCHAR(150) NOT NULL,
    area_type VARCHAR(10),
    boundary geometry(POLYGON, 4326), -- Hệ tọa độ WGS 84 (chuẩn Google Maps)
    code VARCHAR(20),
    parent_id BIGINT REFERENCES administrative_areas(area_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tạo GiST index cho boundary
CREATE INDEX idx_areas_boundary ON administrative_areas USING GIST (boundary);
CREATE INDEX idx_areas_parent_id ON administrative_areas(parent_id);
CREATE INDEX idx_areas_type ON administrative_areas(area_type);

-- 3.1. Seed administrative_areas
INSERT INTO administrative_areas (area_id, area_name, area_type, code) VALUES (1, 'Thành phố Hồ Chí Minh', 'PROVINCE', 'SG');

INSERT INTO administrative_areas (area_id, area_name, area_type, code, parent_id) VALUES 
(2, 'Quận 1', 'DISTRICT', 'Q1', 1),
(3, 'Quận 7', 'DISTRICT', 'Q7', 1),
(4, 'Thành phố Thủ Đức', 'DISTRICT', 'TD', 1),
(5, 'Quận Bình Thạnh', 'DISTRICT', 'BT', 1);

INSERT INTO administrative_areas (area_id, area_name, area_type, code, parent_id) VALUES 
(6, 'Phường Bến Nghé', 'WARD', 'BN', 2),
(7, 'Phường Bến Thành', 'WARD', 'BTH', 2),
(8, 'Phường Đa Kao', 'WARD', 'DK', 2);

SELECT setval('administrative_areas_area_id_seq', 8);

-- 4. Table properties
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
    property_type VARCHAR(50) DEFAULT 'BOARDING_HOUSE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_properties_landlord_id ON properties(landlord_id);

-- 5. Table rooms
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

-- 6. Table property_images
CREATE TABLE property_images (
    id BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_property_images_property_id ON property_images(property_id);

-- 7. Table favorite_properties
CREATE TABLE favorite_properties (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    property_id BIGINT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_property UNIQUE (user_id, property_id)
);

CREATE INDEX idx_favorites_user_id     ON favorite_properties(user_id);
CREATE INDEX idx_favorites_property_id ON favorite_properties(property_id);

-- 8. Table listings (PostGIS)
CREATE TABLE listings (
    listing_id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users(user_id),
    area_id BIGINT NOT NULL REFERENCES administrative_areas(area_id),
    approved_by BIGINT REFERENCES users(user_id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    listing_type VARCHAR(15) NOT NULL CHECK (listing_type IN ('WHOLE_HOUSE', 'BOARDING_ROOM', 'SHARED_ROOM')),
    rent_price DECIMAL(12,2) NOT NULL,
    area_sqm DECIMAL(6,2),
    address VARCHAR(255),
    location geometry(POINT, 4326), -- Hệ tọa độ WGS 84
    approval_status VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    rental_status VARCHAR(15) NOT NULL DEFAULT 'AVAILABLE' CHECK (rental_status IN ('AVAILABLE', 'RENTED')),
    rejection_reason VARCHAR(255),
    is_vip BOOLEAN DEFAULT FALSE,
    vip_expires_at TIMESTAMP,
    refreshed_at TIMESTAMP,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX idx_listings_area_id ON listings(area_id);
CREATE INDEX idx_listings_owner_id ON listings(owner_id);
CREATE INDEX idx_listings_status ON listings(approval_status);
CREATE INDEX idx_listings_location ON listings USING GIST (location);

-- 9. Table listing_images
CREATE TABLE listing_images (
    image_id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    image_url VARCHAR(255) NOT NULL,
    is_thumbnail BOOLEAN DEFAULT FALSE,
    sort_order SMALLINT DEFAULT 0
);

-- 10. Table furniture
CREATE TABLE furniture (
    furniture_id BIGSERIAL PRIMARY KEY,
    furniture_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    icon_url VARCHAR(255)
);

-- 11. Table listing_furniture
CREATE TABLE listing_furniture (
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    furniture_id BIGINT NOT NULL REFERENCES furniture(furniture_id) ON DELETE CASCADE,
    quantity SMALLINT DEFAULT 1,
    PRIMARY KEY (listing_id, furniture_id)
);

-- 12. Table followed_listings
CREATE TABLE followed_listings (
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, listing_id)
);

-- 13. Table contracts
CREATE TABLE contracts (
    contract_id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id),
    landlord_id BIGINT NOT NULL REFERENCES users(user_id),
    tenant_id BIGINT NOT NULL REFERENCES users(user_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent DECIMAL(12,2) NOT NULL,
    deposit_amount DECIMAL(12,2),
    status VARCHAR(15) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'TERMINATED')),
    contract_file_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. Table membership_packages
CREATE TABLE membership_packages (
    package_id SMALLSERIAL PRIMARY KEY,
    package_name VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    standard_post_quota SMALLINT NOT NULL,
    vip_post_quota SMALLINT NOT NULL DEFAULT 0,
    refresh_quota SMALLINT NOT NULL DEFAULT 0,
    description VARCHAR(255)
);

-- 15. Table user_subscriptions
CREATE TABLE user_subscriptions (
    subscription_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    package_id SMALLINT NOT NULL REFERENCES membership_packages(package_id),
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remaining_standard_quota SMALLINT,
    remaining_vip_quota SMALLINT,
    remaining_refresh_quota SMALLINT,
    quota_reset_at TIMESTAMP,
    status VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED'))
);

-- 16. Table payment_transactions
CREATE TABLE payment_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    subscription_id BIGINT UNIQUE REFERENCES user_subscriptions(subscription_id),
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'VNPAY',
    vnpay_transaction_ref VARCHAR(100),
    status VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED')),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 17. Table notifications
CREATE TABLE notifications (
    notification_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    notification_type VARCHAR(30) NOT NULL,
    title VARCHAR(150),
    content VARCHAR(500),
    listing_id BIGINT REFERENCES listings(listing_id),
    contract_id BIGINT REFERENCES contracts(contract_id),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 18. Table contact_messages
CREATE TABLE contact_messages (
    message_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    full_name VARCHAR(150),
    email VARCHAR(150),
    subject VARCHAR(150),
    content TEXT,
    status VARCHAR(15) DEFAULT 'NEW' CHECK (status IN ('NEW', 'RESOLVED')),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 19. Table system_content
CREATE TABLE system_content (
    content_id SMALLSERIAL PRIMARY KEY,
    page_key VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(200),
    body TEXT,
    updated_by BIGINT REFERENCES users(user_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 20. Table qr_login_sessions
CREATE TABLE qr_login_sessions (
    session_id UUID PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    status VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SCANNED', 'CONFIRMED', 'EXPIRED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Add advanced details to listings
-- V5: Add advanced detail columns to listings table for multi-step property creation flow
-- These fields support both "Whole House" (Nhà ở) and "Room" (Phòng trọ) listing types.
-- House-specific fields are nullable so Room listings can omit them.

ALTER TABLE listings ADD COLUMN IF NOT EXISTS house_type       VARCHAR(50);   -- MAT_PHO | NGO_HEM | BIET_THU | LIEN_KE
ALTER TABLE listings ADD COLUMN IF NOT EXISTS bedrooms         INT;           -- Number of bedrooms
ALTER TABLE listings ADD COLUMN IF NOT EXISTS bathrooms        INT;           -- Number of bathrooms
ALTER TABLE listings ADD COLUMN IF NOT EXISTS total_floors     INT;           -- Total number of floors
ALTER TABLE listings ADD COLUMN IF NOT EXISTS door_direction   VARCHAR(50);   -- NORTH | SOUTH | EAST | WEST | NORTHEAST | ...
ALTER TABLE listings ADD COLUMN IF NOT EXISTS legal_documents  VARCHAR(100);  -- PINK_BOOK | RED_BOOK | SALE_CONTRACT | NONE
ALTER TABLE listings ADD COLUMN IF NOT EXISTS furniture_status VARCHAR(50);   -- FULL | BASIC | EMPTY
ALTER TABLE listings ADD COLUMN IF NOT EXISTS deposit_amount   DECIMAL(12,2); -- Security deposit amount
ALTER TABLE listings ADD COLUMN IF NOT EXISTS poster_type      VARCHAR(20);   -- CA_NHAN (private owner) | MOI_GIOI (broker)

COMMENT ON COLUMN listings.house_type IS 'Loại nhà: MAT_PHO (mặt phố), NGO_HEM (ngõ hẻm), BIET_THU (biệt thự), LIEN_KE (liền kề)';
COMMENT ON COLUMN listings.bedrooms IS 'Số phòng ngủ';
COMMENT ON COLUMN listings.bathrooms IS 'Số phòng tắm / vệ sinh';
COMMENT ON COLUMN listings.total_floors IS 'Tổng số tầng của toà nhà';
COMMENT ON COLUMN listings.door_direction IS 'Hướng cửa chính: NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST';
COMMENT ON COLUMN listings.legal_documents IS 'Giấy tờ pháp lý: PINK_BOOK, RED_BOOK, SALE_CONTRACT, NONE';
COMMENT ON COLUMN listings.furniture_status IS 'Tình trạng nội thất: FULL (đầy đủ), BASIC (cơ bản), EMPTY (không có)';
COMMENT ON COLUMN listings.deposit_amount IS 'Tiền đặt cọc (VND)';
COMMENT ON COLUMN listings.poster_type IS 'Loại người đăng: CA_NHAN (cá nhân), MOI_GIOI (môi giới)';

-- seed membership packages
INSERT INTO membership_packages (package_name, price, standard_post_quota, vip_post_quota, refresh_quota, description) VALUES
('Gói Cơ Bản', 0, 3, 0, 0, 'Phù hợp cho người dùng cá nhân có nhu cầu đăng tin thỉnh thoảng.'),
('Gói Tiêu Chuẩn', 50000, 10, 0, 5, 'Dành cho môi giới vừa và nhỏ, cần đăng nhiều tin hơn.'),
('Gói VIP', 150000, 30, 5, 20, 'Gói ưu đãi cao cấp giúp tin của bạn nổi bật hơn (Tin VIP) và thêm nhiều lượt đẩy tin lên top.');

-- create user favorites
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

-- listing management statuses
-- Keep listings referenced by contracts when their owner removes them.
ALTER TABLE listings DROP CONSTRAINT IF EXISTS listings_rental_status_check;
ALTER TABLE listings ADD CONSTRAINT listings_rental_status_check
    CHECK (rental_status IN ('AVAILABLE', 'RENTED', 'HIDDEN', 'DELETED'));
CREATE INDEX IF NOT EXISTS idx_listings_owner_created ON listings(owner_id, created_at DESC);

-- repair seed area names utf8
-- Repair legacy seed names whose Vietnamese characters were replaced during import.
-- Match seed identity and only update damaged text, preserving custom area names.
UPDATE administrative_areas AS area
SET area_name = seed.correct_name
FROM (VALUES
    (1::bigint, 'PROVINCE', 'SG', 'Thành phố Hồ Chí Minh'),
    (2::bigint, 'DISTRICT', 'Q1', 'Quận 1'),
    (3::bigint, 'DISTRICT', 'Q7', 'Quận 7'),
    (4::bigint, 'DISTRICT', 'TD', 'Thành phố Thủ Đức'),
    (5::bigint, 'DISTRICT', 'BT', 'Quận Bình Thạnh'),
    (6::bigint, 'WARD', 'BN', 'Phường Bến Nghé'),
    (7::bigint, 'WARD', 'BTH', 'Phường Bến Thành'),
    (8::bigint, 'WARD', 'DK', 'Phường Đa Kao')
) AS seed(area_id, area_type, code, correct_name)
WHERE area.area_id = seed.area_id
  AND area.area_type = seed.area_type
  AND area.code = seed.code
  AND (position('?' IN area.area_name) > 0
       OR position(U&'\FFFD' IN area.area_name) > 0);

-- hcm post merger commune level areas
-- TP.HCM: 168 commune-level units under Resolution 1685/NQ-UBTVQH15 (2025-06-16).
-- Source: https://xaydungchinhsach.chinhphu.vn/sap-xep-dvhc-danh-sach-168-xa-phuong-dac-khu-cua-thanh-pho-ho-chi-minh-119250623085031865.htm
-- HCM25-* are stable application identifiers, NOT official administrative codes.
-- Keep legacy districts/wards and references unchanged. New units are province children.
ALTER TABLE properties ALTER COLUMN district_id DROP NOT NULL;

WITH units(code, area_name, area_type) AS (VALUES
    ('HCM25-001', 'Phường Sài Gòn', 'WARD'),
    ('HCM25-002', 'Phường Tân Định', 'WARD'),
    ('HCM25-003', 'Phường Bến Thành', 'WARD'),
    ('HCM25-004', 'Phường Cầu Ông Lãnh', 'WARD'),
    ('HCM25-005', 'Phường Bàn Cờ', 'WARD'),
    ('HCM25-006', 'Phường Xuân Hòa', 'WARD'),
    ('HCM25-007', 'Phường Nhiêu Lộc', 'WARD'),
    ('HCM25-008', 'Phường Xóm Chiếu', 'WARD'),
    ('HCM25-009', 'Phường Khánh Hội', 'WARD'),
    ('HCM25-010', 'Phường Vĩnh Hội', 'WARD'),
    ('HCM25-011', 'Phường Chợ Quán', 'WARD'),
    ('HCM25-012', 'Phường An Đông', 'WARD'),
    ('HCM25-013', 'Phường Chợ Lớn', 'WARD'),
    ('HCM25-014', 'Phường Bình Tây', 'WARD'),
    ('HCM25-015', 'Phường Bình Tiên', 'WARD'),
    ('HCM25-016', 'Phường Bình Phú', 'WARD'),
    ('HCM25-017', 'Phường Phú Lâm', 'WARD'),
    ('HCM25-018', 'Phường Tân Thuận', 'WARD'),
    ('HCM25-019', 'Phường Phú Thuận', 'WARD'),
    ('HCM25-020', 'Phường Tân Mỹ', 'WARD'),
    ('HCM25-021', 'Phường Tân Hưng', 'WARD'),
    ('HCM25-022', 'Phường Chánh Hưng', 'WARD'),
    ('HCM25-023', 'Phường Phú Định', 'WARD'),
    ('HCM25-024', 'Phường Bình Đông', 'WARD'),
    ('HCM25-025', 'Phường Diên Hồng', 'WARD'),
    ('HCM25-026', 'Phường Vườn Lài', 'WARD'),
    ('HCM25-027', 'Phường Hòa Hưng', 'WARD'),
    ('HCM25-028', 'Phường Minh Phụng', 'WARD'),
    ('HCM25-029', 'Phường Bình Thới', 'WARD'),
    ('HCM25-030', 'Phường Hòa Bình', 'WARD'),
    ('HCM25-031', 'Phường Phú Thọ', 'WARD'),
    ('HCM25-032', 'Phường Đông Hưng Thuận', 'WARD'),
    ('HCM25-033', 'Phường Trung Mỹ Tây', 'WARD'),
    ('HCM25-034', 'Phường Tân Thới Hiệp', 'WARD'),
    ('HCM25-035', 'Phường Thới An', 'WARD'),
    ('HCM25-036', 'Phường An Phú Đông', 'WARD'),
    ('HCM25-037', 'Phường An Lạc', 'WARD'),
    ('HCM25-038', 'Phường Bình Tân', 'WARD'),
    ('HCM25-039', 'Phường Tân Tạo', 'WARD'),
    ('HCM25-040', 'Phường Bình Trị Đông', 'WARD'),
    ('HCM25-041', 'Phường Bình Hưng Hòa', 'WARD'),
    ('HCM25-042', 'Phường Gia Định', 'WARD'),
    ('HCM25-043', 'Phường Bình Thạnh', 'WARD'),
    ('HCM25-044', 'Phường Bình Lợi Trung', 'WARD'),
    ('HCM25-045', 'Phường Thạnh Mỹ Tây', 'WARD'),
    ('HCM25-046', 'Phường Bình Quới', 'WARD'),
    ('HCM25-047', 'Phường Hạnh Thông', 'WARD'),
    ('HCM25-048', 'Phường An Nhơn', 'WARD'),
    ('HCM25-049', 'Phường Gò Vấp', 'WARD'),
    ('HCM25-050', 'Phường An Hội Đông', 'WARD'),
    ('HCM25-051', 'Phường Thông Tây Hội', 'WARD'),
    ('HCM25-052', 'Phường An Hội Tây', 'WARD'),
    ('HCM25-053', 'Phường Đức Nhuận', 'WARD'),
    ('HCM25-054', 'Phường Cầu Kiệu', 'WARD'),
    ('HCM25-055', 'Phường Phú Nhuận', 'WARD'),
    ('HCM25-056', 'Phường Tân Sơn Hòa', 'WARD'),
    ('HCM25-057', 'Phường Tân Sơn Nhất', 'WARD'),
    ('HCM25-058', 'Phường Tân Hòa', 'WARD'),
    ('HCM25-059', 'Phường Bảy Hiền', 'WARD'),
    ('HCM25-060', 'Phường Tân Bình', 'WARD'),
    ('HCM25-061', 'Phường Tân Sơn', 'WARD'),
    ('HCM25-062', 'Phường Tây Thạnh', 'WARD'),
    ('HCM25-063', 'Phường Tân Sơn Nhì', 'WARD'),
    ('HCM25-064', 'Phường Phú Thọ Hòa', 'WARD'),
    ('HCM25-065', 'Phường Tân Phú', 'WARD'),
    ('HCM25-066', 'Phường Phú Thạnh', 'WARD'),
    ('HCM25-067', 'Phường Hiệp Bình', 'WARD'),
    ('HCM25-068', 'Phường Thủ Đức', 'WARD'),
    ('HCM25-069', 'Phường Tam Bình', 'WARD'),
    ('HCM25-070', 'Phường Linh Xuân', 'WARD'),
    ('HCM25-071', 'Phường Tăng Nhơn Phú', 'WARD'),
    ('HCM25-072', 'Phường Long Bình', 'WARD'),
    ('HCM25-073', 'Phường Long Phước', 'WARD'),
    ('HCM25-074', 'Phường Long Trường', 'WARD'),
    ('HCM25-075', 'Phường Cát Lái', 'WARD'),
    ('HCM25-076', 'Phường Bình Trưng', 'WARD'),
    ('HCM25-077', 'Phường Phước Long', 'WARD'),
    ('HCM25-078', 'Phường An Khánh', 'WARD'),
    ('HCM25-079', 'Phường Đông Hòa', 'WARD'),
    ('HCM25-080', 'Phường Dĩ An', 'WARD'),
    ('HCM25-081', 'Phường Tân Đông Hiệp', 'WARD'),
    ('HCM25-082', 'Phường An Phú', 'WARD'),
    ('HCM25-083', 'Phường Bình Hòa', 'WARD'),
    ('HCM25-084', 'Phường Lái Thiêu', 'WARD'),
    ('HCM25-085', 'Phường Thuận An', 'WARD'),
    ('HCM25-086', 'Phường Thuận Giao', 'WARD'),
    ('HCM25-087', 'Phường Thủ Dầu Một', 'WARD'),
    ('HCM25-088', 'Phường Phú Lợi', 'WARD'),
    ('HCM25-089', 'Phường Chánh Hiệp', 'WARD'),
    ('HCM25-090', 'Phường Bình Dương', 'WARD'),
    ('HCM25-091', 'Phường Hòa Lợi', 'WARD'),
    ('HCM25-092', 'Phường Phú An', 'WARD'),
    ('HCM25-093', 'Phường Tây Nam', 'WARD'),
    ('HCM25-094', 'Phường Long Nguyên', 'WARD'),
    ('HCM25-095', 'Phường Bến Cát', 'WARD'),
    ('HCM25-096', 'Phường Chánh Phú Hòa', 'WARD'),
    ('HCM25-097', 'Phường Vĩnh Tân', 'WARD'),
    ('HCM25-098', 'Phường Bình Cơ', 'WARD'),
    ('HCM25-099', 'Phường Tân Uyên', 'WARD'),
    ('HCM25-100', 'Phường Tân Hiệp', 'WARD'),
    ('HCM25-101', 'Phường Tân Khánh', 'WARD'),
    ('HCM25-102', 'Phường Vũng Tàu', 'WARD'),
    ('HCM25-103', 'Phường Tam Thắng', 'WARD'),
    ('HCM25-104', 'Phường Rạch Dừa', 'WARD'),
    ('HCM25-105', 'Phường Phước Thắng', 'WARD'),
    ('HCM25-106', 'Phường Long Hương', 'WARD'),
    ('HCM25-107', 'Phường Bà Rịa', 'WARD'),
    ('HCM25-108', 'Phường Tam Long', 'WARD'),
    ('HCM25-109', 'Phường Tân Hải', 'WARD'),
    ('HCM25-110', 'Phường Tân Phước', 'WARD'),
    ('HCM25-111', 'Phường Phú Mỹ', 'WARD'),
    ('HCM25-112', 'Phường Tân Thành', 'WARD'),
    ('HCM25-113', 'Xã Vĩnh Lộc', 'COMMUNE'),
    ('HCM25-114', 'Xã Tân Vĩnh Lộc', 'COMMUNE'),
    ('HCM25-115', 'Xã Bình Lợi', 'COMMUNE'),
    ('HCM25-116', 'Xã Tân Nhựt', 'COMMUNE'),
    ('HCM25-117', 'Xã Bình Chánh', 'COMMUNE'),
    ('HCM25-118', 'Xã Hưng Long', 'COMMUNE'),
    ('HCM25-119', 'Xã Bình Hưng', 'COMMUNE'),
    ('HCM25-120', 'Xã Bình Khánh', 'COMMUNE'),
    ('HCM25-121', 'Xã An Thới Đông', 'COMMUNE'),
    ('HCM25-122', 'Xã Cần Giờ', 'COMMUNE'),
    ('HCM25-123', 'Xã Củ Chi', 'COMMUNE'),
    ('HCM25-124', 'Xã Tân An Hội', 'COMMUNE'),
    ('HCM25-125', 'Xã Thái Mỹ', 'COMMUNE'),
    ('HCM25-126', 'Xã An Nhơn Tây', 'COMMUNE'),
    ('HCM25-127', 'Xã Nhuận Đức', 'COMMUNE'),
    ('HCM25-128', 'Xã Phú Hòa Đông', 'COMMUNE'),
    ('HCM25-129', 'Xã Bình Mỹ', 'COMMUNE'),
    ('HCM25-130', 'Xã Đông Thạnh', 'COMMUNE'),
    ('HCM25-131', 'Xã Hóc Môn', 'COMMUNE'),
    ('HCM25-132', 'Xã Xuân Thới Sơn', 'COMMUNE'),
    ('HCM25-133', 'Xã Bà Điểm', 'COMMUNE'),
    ('HCM25-134', 'Xã Nhà Bè', 'COMMUNE'),
    ('HCM25-135', 'Xã Hiệp Phước', 'COMMUNE'),
    ('HCM25-136', 'Xã Thường Tân', 'COMMUNE'),
    ('HCM25-137', 'Xã Bắc Tân Uyên', 'COMMUNE'),
    ('HCM25-138', 'Xã Phú Giáo', 'COMMUNE'),
    ('HCM25-139', 'Xã Phước Hòa', 'COMMUNE'),
    ('HCM25-140', 'Xã Phước Thành', 'COMMUNE'),
    ('HCM25-141', 'Xã An Long', 'COMMUNE'),
    ('HCM25-142', 'Xã Trừ Văn Thố', 'COMMUNE'),
    ('HCM25-143', 'Xã Bàu Bàng', 'COMMUNE'),
    ('HCM25-144', 'Xã Long Hòa', 'COMMUNE'),
    ('HCM25-145', 'Xã Thanh An', 'COMMUNE'),
    ('HCM25-146', 'Xã Dầu Tiếng', 'COMMUNE'),
    ('HCM25-147', 'Xã Minh Thạnh', 'COMMUNE'),
    ('HCM25-148', 'Xã Châu Pha', 'COMMUNE'),
    ('HCM25-149', 'Xã Long Hải', 'COMMUNE'),
    ('HCM25-150', 'Xã Long Điền', 'COMMUNE'),
    ('HCM25-151', 'Xã Phước Hải', 'COMMUNE'),
    ('HCM25-152', 'Xã Đất Đỏ', 'COMMUNE'),
    ('HCM25-153', 'Xã Nghĩa Thành', 'COMMUNE'),
    ('HCM25-154', 'Xã Ngãi Giao', 'COMMUNE'),
    ('HCM25-155', 'Xã Kim Long', 'COMMUNE'),
    ('HCM25-156', 'Xã Châu Đức', 'COMMUNE'),
    ('HCM25-157', 'Xã Bình Giã', 'COMMUNE'),
    ('HCM25-158', 'Xã Xuân Sơn', 'COMMUNE'),
    ('HCM25-159', 'Xã Hồ Tràm', 'COMMUNE'),
    ('HCM25-160', 'Xã Xuyên Mộc', 'COMMUNE'),
    ('HCM25-161', 'Xã Hòa Hội', 'COMMUNE'),
    ('HCM25-162', 'Xã Bàu Lâm', 'COMMUNE'),
    ('HCM25-163', 'Đặc khu Côn Đảo', 'SPECIAL'),
    ('HCM25-164', 'Phường Thới Hòa', 'WARD'),
    ('HCM25-165', 'Xã Long Sơn', 'COMMUNE'),
    ('HCM25-166', 'Xã Hòa Hiệp', 'COMMUNE'),
    ('HCM25-167', 'Xã Bình Châu', 'COMMUNE'),
    ('HCM25-168', 'Xã Thạnh An', 'COMMUNE')
)
INSERT INTO administrative_areas (area_name, area_type, code, parent_id)
SELECT u.area_name, u.area_type, u.code, p.area_id
FROM units u CROSS JOIN administrative_areas p
WHERE p.area_type = 'PROVINCE' AND p.code = 'SG'
  AND NOT EXISTS (SELECT 1 FROM administrative_areas a WHERE a.parent_id = p.area_id AND a.code = u.code);

-- contract management
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

-- contract templates
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS contract_type VARCHAR(20);
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS details_json TEXT;
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS document_text TEXT;
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP;

-- rename membership packages
UPDATE membership_packages
SET package_name = 'Gói PLUS'
WHERE LOWER(TRIM(package_name)) IN ('gói tiêu chuẩn', 'tiêu chuẩn');

UPDATE membership_packages
SET package_name = 'Gói PRO'
WHERE LOWER(TRIM(package_name)) IN ('gói vip', 'vip');

-- shared room details
ALTER TABLE listings
    ADD COLUMN current_occupants INTEGER,
    ADD COLUMN max_occupants INTEGER,
    ADD COLUMN gender_preference VARCHAR(20),
    ADD COLUMN allow_pets BOOLEAN,
    ADD COLUMN allow_smoking BOOLEAN,
    ADD COLUMN roommate_requirements VARCHAR(500);

UPDATE listings SET current_occupants = 1, max_occupants = 2,
    gender_preference = 'ANY', allow_pets = FALSE, allow_smoking = FALSE
WHERE listing_type = 'SHARED_ROOM';

ALTER TABLE listings ADD CONSTRAINT valid_shared_room_details CHECK (
    listing_type <> 'SHARED_ROOM' OR (
        current_occupants IS NOT NULL AND max_occupants IS NOT NULL
        AND current_occupants >= 0 AND max_occupants <= 20
        AND max_occupants > current_occupants
        AND gender_preference IS NOT NULL AND gender_preference IN ('ANY', 'MALE', 'FEMALE')
    )
);

-- user personal interests
CREATE TABLE user_preference_interests (
    preference_id BIGINT NOT NULL REFERENCES user_preferences(preference_id) ON DELETE CASCADE,
    interest_code VARCHAR(32) NOT NULL,
    PRIMARY KEY (preference_id, interest_code),
    CONSTRAINT valid_personal_interest CHECK (interest_code IN (
        'CAT_LOVER', 'DOG_LOVER', 'PLANTS', 'QUIET', 'TIDY', 'STUDY', 'EARLY_BIRD', 'NIGHT_OWL', 'NON_SMOKER', 'SOCIABLE', 'MUSIC', 'MOVIES', 'READING', 'GAMING', 'COOKING', 'SPORTS', 'TRAVEL', 'COFFEE'
    ))
);

-- notification indexes
UPDATE notifications SET is_read = FALSE WHERE is_read IS NULL;
ALTER TABLE notifications ALTER COLUMN is_read SET NOT NULL;
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC, notification_id DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE is_read = FALSE;

-- merge user roles into member
ALTER TABLE users DROP CONSTRAINT users_role_check;

UPDATE users SET role = 'MEMBER' WHERE role IN ('USER', 'OWNER');

ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('MEMBER', 'ADMIN'));

-- administrative area status
ALTER TABLE administrative_areas ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
CREATE INDEX idx_areas_parent_active ON administrative_areas(parent_id, is_active);

-- system content
CREATE TABLE system_contents (
    slug VARCHAR(20) PRIMARY KEY CHECK (slug IN ('about','rules','guide','contact','support')),
    title VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    published_title VARCHAR(150),
    published_body TEXT,
    published BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CHECK (NOT published OR (published_title IS NOT NULL AND published_body IS NOT NULL AND published_at IS NOT NULL))
);

WITH initial(slug, title, body) AS (VALUES
    ('about', 'Giới thiệu', 'Ứng dụng kết nối người thuê và người cho thuê tại TP.HCM, hỗ trợ đăng tin, tìm nhà trên bản đồ và quản lý hợp đồng.'),
    ('rules', 'Quy định đăng tin', 'Cung cấp đúng địa chỉ, giá thuê và ảnh thực tế. Tin mới và tin chỉnh sửa phải được Admin duyệt trước khi xuất hiện công khai.'),
    ('guide', 'Hướng dẫn sử dụng', E'1. Chọn Đăng Tin và điền thông tin nhà hoặc phòng.\n2. Gửi tin để Admin duyệt.\n3. Xem trạng thái trong Quản Lý Tin Đăng.\n4. Tìm nhà đã duyệt ở mục Thuê Nhà, Thuê Phòng Trọ, Tìm Ở Ghép hoặc Bản Đồ.'),
    ('contact', 'Liên hệ', 'Thông tin liên hệ hỗ trợ sẽ được cập nhật khi hệ thống chính thức triển khai.'),
    ('support', 'Báo cáo sự cố', 'Ghi lại thao tác gặp lỗi và ảnh màn hình, sau đó gửi cho người quản trị theo thông tin ở mục Liên hệ. Chức năng gửi báo cáo trực tiếp trong ứng dụng chưa được kết nối.')
)
INSERT INTO system_contents (slug, title, body, published_title, published_body, published, published_at)
SELECT slug, title, body, title, body, TRUE, CURRENT_TIMESTAMP FROM initial;

-- password version
ALTER TABLE users ADD COLUMN password_version INTEGER NOT NULL DEFAULT 0;

-- incident reports
CREATE TABLE incident_reports (
    id BIGSERIAL PRIMARY KEY,
    reporter_id BIGINT NOT NULL REFERENCES users(user_id),
    request_key VARCHAR(80) NOT NULL,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(20) NOT NULL CHECK (category IN ('ACCOUNT','LISTING','CONTRACT','PAYMENT','TECHNICAL','OTHER')),
    description VARCHAR(5000) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED','REJECTED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    UNIQUE (reporter_id, request_key)
);
CREATE TABLE incident_updates (
    id BIGSERIAL PRIMARY KEY,
    incident_id BIGINT NOT NULL REFERENCES incident_reports(id),
    actor_id BIGINT NOT NULL REFERENCES users(user_id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED','REJECTED')),
    message VARCHAR(2000) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_incidents_reporter_created ON incident_reports(reporter_id, created_at DESC);
CREATE INDEX idx_incidents_status_updated ON incident_reports(status, updated_at DESC, id DESC);
CREATE INDEX idx_incident_updates_report ON incident_updates(incident_id, created_at, id);
ALTER TABLE notifications ADD COLUMN incident_id BIGINT REFERENCES incident_reports(id);

-- admin membership packages
ALTER TABLE membership_packages ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE membership_packages ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
CREATE UNIQUE INDEX idx_membership_package_name_unique ON membership_packages(lower(package_name));
ALTER TABLE user_subscriptions ADD COLUMN package_name_snapshot VARCHAR(20);
UPDATE user_subscriptions s SET package_name_snapshot = p.package_name FROM membership_packages p WHERE s.package_id = p.package_id;
ALTER TABLE user_subscriptions ALTER COLUMN remaining_standard_quota TYPE INTEGER;
ALTER TABLE user_subscriptions ALTER COLUMN remaining_vip_quota TYPE INTEGER;
ALTER TABLE user_subscriptions ALTER COLUMN remaining_refresh_quota TYPE INTEGER;
ALTER TABLE payment_transactions ADD COLUMN package_id SMALLINT REFERENCES membership_packages(package_id);
ALTER TABLE payment_transactions ADD COLUMN package_name_snapshot VARCHAR(20);
ALTER TABLE payment_transactions ADD COLUMN standard_quota_snapshot SMALLINT;
ALTER TABLE payment_transactions ADD COLUMN vip_quota_snapshot SMALLINT;
ALTER TABLE payment_transactions ADD COLUMN refresh_quota_snapshot SMALLINT;
UPDATE payment_transactions t SET package_id=p.package_id, package_name_snapshot=p.package_name,
    standard_quota_snapshot=p.standard_post_quota, vip_quota_snapshot=p.vip_post_quota, refresh_quota_snapshot=p.refresh_quota
FROM membership_packages p WHERE split_part(t.vnpay_transaction_ref, '_', 1) = p.package_id::text;
CREATE INDEX idx_payments_package_id ON payment_transactions(package_id);

-- nearby listing index
CREATE INDEX IF NOT EXISTS idx_listings_available_geography
ON listings USING GIST ((CAST(location AS geography)))
WHERE location IS NOT NULL AND approval_status = 'APPROVED' AND rental_status = 'AVAILABLE';

-- default membership
ALTER TABLE membership_packages ADD COLUMN is_default BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO membership_packages (package_name, price, standard_post_quota, vip_post_quota, refresh_quota, description, active, version)
SELECT 'Gói Cơ Bản', 0, 3, 0, 0, 'Gói mặc định cho tài khoản Member.', TRUE, 0
WHERE NOT EXISTS (SELECT 1 FROM membership_packages WHERE price = 0);

UPDATE membership_packages SET is_default = TRUE, active = TRUE
WHERE package_id = (SELECT package_id FROM membership_packages WHERE price = 0 ORDER BY package_id LIMIT 1);

CREATE UNIQUE INDEX idx_membership_default_unique ON membership_packages (is_default) WHERE is_default = TRUE;
ALTER TABLE membership_packages ADD CONSTRAINT ck_default_membership_free_active CHECK (NOT is_default OR (price = 0 AND active = TRUE));
CREATE UNIQUE INDEX idx_user_subscription_unique ON user_subscriptions (user_id);

INSERT INTO user_subscriptions (user_id, package_id, purchased_at, remaining_standard_quota, remaining_vip_quota,
    remaining_refresh_quota, quota_reset_at, status, package_name_snapshot)
SELECT u.user_id, p.package_id, CURRENT_TIMESTAMP, p.standard_post_quota, p.vip_post_quota, p.refresh_quota,
    NULL, 'ACTIVE', p.package_name
FROM users u CROSS JOIN membership_packages p
WHERE p.is_default = TRUE AND u.role = 'MEMBER' AND u.is_verified = TRUE AND u.status = 'ACTIVE'
    AND NOT EXISTS (SELECT 1 FROM user_subscriptions s WHERE s.user_id = u.user_id);

-- amenities
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

-- vnpay payment results
ALTER TABLE payment_transactions ADD COLUMN vnpay_response_code VARCHAR(2);
CREATE INDEX idx_payment_user_date ON payment_transactions (user_id, transaction_date DESC);

-- admin qr login
CREATE TABLE admin_qr_logins (
    id VARCHAR(36) PRIMARY KEY,
    browser_secret_hash VARCHAR(64) NOT NULL,
    scan_secret_hash VARCHAR(64) NOT NULL,
    verification_code VARCHAR(6) NOT NULL,
    browser_name VARCHAR(80) NOT NULL,
    website VARCHAR(200) NOT NULL,
    requester_hash VARCHAR(64) NOT NULL,
    status VARCHAR(12) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','SCANNED','APPROVED','REJECTED','CANCELLED','CONSUMED')),
    admin_id BIGINT REFERENCES users(user_id),
    password_version INTEGER,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_admin_qr_expiry ON admin_qr_logins(expires_at);
CREATE INDEX idx_admin_qr_requester ON admin_qr_logins(requester_hash, created_at);

-- chat history
CREATE TABLE chatbot_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    request_json TEXT NOT NULL,
    reply_json TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chatbot_history_user_id ON chatbot_history(user_id, id DESC);

-- refresh default help content
WITH replacement(slug, old_body, new_body) AS (VALUES
    ('about', 'Ứng dụng kết nối người thuê và người cho thuê tại TP.HCM, hỗ trợ đăng tin, tìm nhà trên bản đồ và quản lý hợp đồng.', $article$<h2>Một nơi ở phù hợp, một trải nghiệm dễ dàng</h2><p>Rental kết nối người tìm nhà, phòng trọ và người ở ghép với các tin cho thuê được công bố trong hệ thống.</p><h3>Dành cho người tìm nơi ở</h3><ul><li>Tìm kiếm theo khu vực, giá thuê, diện tích và tiện ích.</li><li>Xem bản đồ, tìm quanh một vị trí và lưu những tin yêu thích.</li><li>Trao đổi với trợ lý tìm nhà chạy nội bộ theo các điều kiện bạn cung cấp.</li></ul><h3>Dành cho người cho thuê</h3><ul><li>Đăng tin, cập nhật trạng thái còn trống hoặc đã cho thuê.</li><li>Theo dõi quá trình duyệt tin và quản lý hợp đồng của tài khoản.</li><li>Xem các gói dịch vụ và quyền lợi phù hợp với nhu cầu.</li></ul><p>Các tin phải được duyệt trước khi xuất hiện công khai. Bạn nên kiểm tra thông tin thực tế và trao đổi rõ với bên cho thuê trước khi quyết định.</p>$article$),
    ('rules', 'Cung cấp đúng địa chỉ, giá thuê và ảnh thực tế. Tin mới và tin chỉnh sửa phải được Admin duyệt trước khi xuất hiện công khai.', $article$<h2>Cùng giữ thông tin rõ ràng và đáng tin cậy</h2><h3>Thông tin tin đăng</h3><ul><li>Sử dụng tiêu đề, địa chỉ, giá thuê, diện tích và hình ảnh phản ánh đúng thực tế.</li><li>Chỉ đăng nội dung mà bạn có quyền cung cấp. Không đưa thông tin cá nhân của người khác lên tin khi chưa được đồng ý.</li><li>Không đăng nội dung giả mạo, xúc phạm, gây hiểu nhầm hoặc không liên quan đến nhu cầu thuê và cho thuê.</li></ul><h3>Kiểm duyệt và cập nhật</h3><p>Tin mới và tin chỉnh sửa phải chờ Admin duyệt. Khi không còn nhu cầu cho thuê, hãy ẩn tin hoặc đánh dấu đã cho thuê trong Quản lý tin đăng.</p><h3>Sử dụng tài khoản</h3><p>Giữ kín mật khẩu và mã xác thực. Chỉ sử dụng các quyền được cấp cho tài khoản của mình.</p><h3>Khi có vấn đề</h3><p>Sử dụng Báo cáo sự cố để phản ánh thông tin sai hoặc lỗi gặp phải. Mô tả cụ thể để đội ngũ quản trị có cơ sở kiểm tra.</p>$article$),
    ('guide', E'1. Chọn Đăng Tin và điền thông tin nhà hoặc phòng.\n2. Gửi tin để Admin duyệt.\n3. Xem trạng thái trong Quản Lý Tin Đăng.\n4. Tìm nhà đã duyệt ở mục Thuê Nhà, Thuê Phòng Trọ, Tìm Ở Ghép hoặc Bản Đồ.', $article$<h2>Bắt đầu theo nhu cầu của bạn</h2><h3>1. Tìm một nơi ở</h3><p>Mở Thuê Nhà, Thuê Phòng Trọ hoặc Tìm Ở Ghép từ trang chủ. Nhập từ khóa, chọn bộ lọc và mở tin để xem thông tin chi tiết.</p><h3>2. Tìm trên bản đồ</h3><p>Mở Bản Đồ để xem vị trí tin. Khi tìm theo bán kính, chọn điểm làm tâm tìm kiếm và khoảng cách phù hợp. Khoảng cách hiển thị là đường chim bay.</p><h3>3. Lưu những tin quan tâm</h3><p>Nhấn trái tim trên tin để lưu vào Yêu thích và mở lại khi cần.</p><h3>4. Đăng và quản lý tin</h3><p>Chọn Đăng Tin, điền loại bất động sản, vị trí, thông tin chi tiết, giá thuê và hình ảnh rồi gửi duyệt. Theo dõi trong Quản Lý Tin Đăng; tin chỉnh sửa sẽ chờ duyệt lại.</p><h3>5. Hợp đồng và gói dịch vụ</h3><p>Mở Quản Lý Hợp Đồng để thao tác với hợp đồng của bạn. Mở Gói Dịch Vụ để xem quyền lợi và lựa chọn gói theo nhu cầu.</p><h3>6. Nhận hỗ trợ</h3><p>Mở Báo Cáo Sự Cố để gửi vấn đề và theo dõi phản hồi. Thông báo trong ứng dụng giúp bạn biết các cập nhật liên quan đến tài khoản.</p>$article$),
    ('contact', 'Thông tin liên hệ hỗ trợ sẽ được cập nhật khi hệ thống chính thức triển khai.', $article$<h2>Bạn cần chúng tôi hỗ trợ?</h2><p>Với lỗi ứng dụng, vấn đề tài khoản, tin đăng, hợp đồng hoặc thanh toán, hãy dùng nút <strong>Gửi và theo dõi báo cáo</strong> bên dưới. Bạn có thể xem tiến độ và phản hồi trong mục Báo cáo sự cố.</p><h3>Thông tin nên chuẩn bị</h3><ul><li>Chức năng và thao tác gặp vấn đề.</li><li>Mã tin, mã hợp đồng hoặc mã giao dịch có liên quan nếu có.</li><li>Thời điểm và nội dung thông báo lỗi.</li></ul><h3>Kênh liên hệ khác</h3><p>Email và số điện thoại hỗ trợ sẽ được công bố tại trang này khi có thông tin chính thức. Không gửi mật khẩu hoặc mã OTP trong nội dung liên hệ.</p>$article$),
    ('support', 'Ghi lại thao tác gặp lỗi và ảnh màn hình, sau đó gửi cho người quản trị theo thông tin ở mục Liên hệ. Chức năng gửi báo cáo trực tiếp trong ứng dụng chưa được kết nối.', $article$<h2>Gửi báo cáo ngay trong ứng dụng</h2><ol><li>Mở Báo cáo sự cố và chọn <strong>Gửi báo cáo mới</strong>.</li><li>Chọn loại sự cố: tài khoản, tin đăng, hợp đồng, thanh toán, lỗi ứng dụng hoặc vấn đề khác.</li><li>Nhập tiêu đề ngắn gọn và mô tả các bước đã thực hiện, kết quả mong đợi, kết quả thực tế và mã liên quan nếu có.</li><li>Nhấn <strong>Gửi báo cáo</strong>. Sau khi được tiếp nhận, bạn có thể mở chi tiết để theo dõi.</li></ol><h3>Theo dõi tiến độ</h3><p>Báo cáo có các trạng thái Mới gửi, Đang xử lý, Đã giải quyết hoặc Từ chối. Phản hồi và các lần cập nhật xuất hiện trong Lịch sử xử lý của từng báo cáo.</p><h3>Nếu gửi thất bại</h3><p>Kiểm tra kết nối và thử gửi lại trên màn hình đang mở. Nội dung đã nhập được giữ lại khi thao tác thất bại.</p>$article$)
)
UPDATE system_contents AS content
SET body = replacement.new_body,
    published_body = replacement.new_body,
    published_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    version = content.version + 1
FROM replacement
WHERE content.slug = replacement.slug
  AND content.version = 0
  AND content.published = TRUE
  AND content.body = replacement.old_body
  AND content.published_body = replacement.old_body;

COMMIT;
