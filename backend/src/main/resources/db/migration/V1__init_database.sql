
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
    role VARCHAR(10) NOT NULL CHECK (role IN ('user', 'admin')),
    status VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'locked')),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- 2. Table user_preferences
CREATE TABLE user_preferences (
    preference_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    preference_group VARCHAR(50) NOT NULL,
    preference_value VARCHAR(100) NOT NULL
);

-- 3. Table administrative_areas (PostGIS)
CREATE TABLE administrative_areas (
    area_id BIGSERIAL PRIMARY KEY,
    area_name VARCHAR(150) NOT NULL,
    area_type VARCHAR(10),
    boundary geometry(POLYGON, 4326), -- Hệ tọa độ WGS 84 (chuẩn Google Maps)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tạo GiST index cho boundary
CREATE INDEX idx_areas_boundary ON administrative_areas USING GIST (boundary);

-- 4. Table listings (PostGIS)
CREATE TABLE listings (
    listing_id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES users(user_id),
    area_id BIGINT NOT NULL REFERENCES administrative_areas(area_id),
    approved_by BIGINT REFERENCES users(user_id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    listing_type VARCHAR(15) NOT NULL CHECK (listing_type IN ('whole_house', 'boarding_room', 'shared_room')),
    rent_price DECIMAL(12,2) NOT NULL,
    area_sqm DECIMAL(6,2),
    address VARCHAR(255),
    location geometry(POINT, 4326), -- Hệ tọa độ WGS 84
    approval_status VARCHAR(15) NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    rental_status VARCHAR(15) NOT NULL DEFAULT 'available' CHECK (rental_status IN ('available', 'rented')),
    rejection_reason VARCHAR(255),
    is_vip BOOLEAN DEFAULT FALSE,
    vip_expires_at TIMESTAMP,
    refreshed_at TIMESTAMP,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Các index cơ bản và GiST index cho location
CREATE INDEX idx_listings_area_id ON listings(area_id);
CREATE INDEX idx_listings_owner_id ON listings(owner_id);
CREATE INDEX idx_listings_status ON listings(approval_status);
CREATE INDEX idx_listings_location ON listings USING GIST (location);

-- 5. Table listing_images
CREATE TABLE listing_images (
    image_id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    image_url VARCHAR(255) NOT NULL,
    is_thumbnail BOOLEAN DEFAULT FALSE,
    sort_order SMALLINT DEFAULT 0
);

-- 6. Table furniture
CREATE TABLE furniture (
    furniture_id BIGSERIAL PRIMARY KEY,
    furniture_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    icon_url VARCHAR(255)
);

-- 7. Table listing_furniture
CREATE TABLE listing_furniture (
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    furniture_id BIGINT NOT NULL REFERENCES furniture(furniture_id) ON DELETE CASCADE,
    quantity SMALLINT DEFAULT 1,
    PRIMARY KEY (listing_id, furniture_id)
);

-- 8. Table followed_listings
CREATE TABLE followed_listings (
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, listing_id)
);

-- 9. Table contracts
CREATE TABLE contracts (
    contract_id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT NOT NULL REFERENCES listings(listing_id),
    landlord_id BIGINT NOT NULL REFERENCES users(user_id),
    tenant_id BIGINT NOT NULL REFERENCES users(user_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent DECIMAL(12,2) NOT NULL,
    deposit_amount DECIMAL(12,2),
    status VARCHAR(15) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'terminated')),
    contract_file_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Table membership_packages
CREATE TABLE membership_packages (
    package_id SMALLSERIAL PRIMARY KEY,
    package_name VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    standard_post_quota SMALLINT NOT NULL,
    vip_post_quota SMALLINT NOT NULL DEFAULT 0,
    refresh_quota SMALLINT NOT NULL DEFAULT 0,
    description VARCHAR(255)
);

-- 11. Table user_subscriptions
CREATE TABLE user_subscriptions (
    subscription_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    package_id SMALLINT NOT NULL REFERENCES membership_packages(package_id),
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remaining_standard_quota SMALLINT,
    remaining_vip_quota SMALLINT,
    remaining_refresh_quota SMALLINT,
    quota_reset_at TIMESTAMP,
    status VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired'))
);

-- 12. Table payment_transactions
CREATE TABLE payment_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    subscription_id BIGINT UNIQUE REFERENCES user_subscriptions(subscription_id),
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'VNPAY',
    vnpay_transaction_ref VARCHAR(100),
    status VARCHAR(15) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed')),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. Table notifications
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

-- 14. Table contact_messages
CREATE TABLE contact_messages (
    message_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    full_name VARCHAR(150),
    email VARCHAR(150),
    subject VARCHAR(150),
    content TEXT,
    status VARCHAR(15) DEFAULT 'new' CHECK (status IN ('new', 'resolved')),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 15. Table system_content
CREATE TABLE system_content (
    content_id SMALLSERIAL PRIMARY KEY,
    page_key VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(200),
    body TEXT,
    updated_by BIGINT REFERENCES users(user_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 16. Table qr_login_sessions
CREATE TABLE qr_login_sessions (
    session_id UUID PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    status VARCHAR(15) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scanned', 'confirmed', 'expired')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);