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
