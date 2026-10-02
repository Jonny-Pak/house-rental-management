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

