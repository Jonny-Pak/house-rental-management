-- Khởi tạo database mới với tên bảng và cột tiếng Việt không dấu.
BEGIN;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = current_schema()
          AND table_name IN ('nguoi_dung', 'users')
    ) THEN
        RAISE EXCEPTION 'Chi chay database.sql tren database/schema moi. Khong chay tren database dang dung.';
    END IF;
END $$;

-- init database
-- Bật extension PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Table users
CREATE TABLE nguoi_dung (
    ma_nguoi_dung BIGSERIAL PRIMARY KEY,
    ho_va_ten VARCHAR(150) NOT NULL,
    dia_chi_thu_dien_tu VARCHAR(150) UNIQUE NOT NULL,
    so_dien_thoai VARCHAR(15) UNIQUE,
    mat_khau_da_bam VARCHAR(255),
    ma_tai_khoan_google VARCHAR(100) UNIQUE,
    duong_dan_anh_dai_dien VARCHAR(255),
    vai_tro VARCHAR(10) NOT NULL CHECK (vai_tro IN ('USER', 'OWNER', 'ADMIN')),
    trang_thai VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (trang_thai IN ('ACTIVE', 'LOCKED')),
    da_xac_thuc_thu_dien_tu BOOLEAN DEFAULT FALSE,
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    thoi_diem_cap_nhat TIMESTAMP
);

-- 2. Table user_preferences
CREATE TABLE so_thich_nguoi_dung (
    ma_ho_so_so_thich BIGSERIAL PRIMARY KEY,
    ma_nguoi_dung BIGINT NOT NULL UNIQUE REFERENCES nguoi_dung(ma_nguoi_dung) ON DELETE CASCADE,
    ngan_sach_toi_thieu DOUBLE PRECISION,
    ngan_sach_toi_da DOUBLE PRECISION,
    co_thu_cung BOOLEAN,
    khu_vuc_mong_muon VARCHAR(150)
);

-- 3. Table administrative_areas (PostGIS)
CREATE TABLE khu_vuc_hanh_chinh (
    ma_khu_vuc BIGSERIAL PRIMARY KEY,
    ten_khu_vuc VARCHAR(150) NOT NULL,
    cap_hanh_chinh VARCHAR(10),
    ranh_gioi_khu_vuc geometry(POLYGON, 4326), -- Hệ tọa độ WGS 84 (chuẩn Google Maps)
    ma_quan_ly VARCHAR(20),
    ma_khu_vuc_cap_tren BIGINT REFERENCES khu_vuc_hanh_chinh(ma_khu_vuc),
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tạo GiST index cho boundary
CREATE INDEX idx_areas_boundary ON khu_vuc_hanh_chinh USING GIST (ranh_gioi_khu_vuc);
CREATE INDEX idx_areas_parent_id ON khu_vuc_hanh_chinh(ma_khu_vuc_cap_tren);
CREATE INDEX idx_areas_type ON khu_vuc_hanh_chinh(cap_hanh_chinh);

-- 3.1. Seed administrative_areas
INSERT INTO khu_vuc_hanh_chinh (ma_khu_vuc, ten_khu_vuc, cap_hanh_chinh, ma_quan_ly) VALUES (1, 'Thành phố Hồ Chí Minh', 'PROVINCE', 'SG');

INSERT INTO khu_vuc_hanh_chinh (ma_khu_vuc, ten_khu_vuc, cap_hanh_chinh, ma_quan_ly, ma_khu_vuc_cap_tren) VALUES 
(2, 'Quận 1', 'DISTRICT', 'Q1', 1),
(3, 'Quận 7', 'DISTRICT', 'Q7', 1),
(4, 'Thành phố Thủ Đức', 'DISTRICT', 'TD', 1),
(5, 'Quận Bình Thạnh', 'DISTRICT', 'BT', 1);

INSERT INTO khu_vuc_hanh_chinh (ma_khu_vuc, ten_khu_vuc, cap_hanh_chinh, ma_quan_ly, ma_khu_vuc_cap_tren) VALUES 
(6, 'Phường Bến Nghé', 'WARD', 'BN', 2),
(7, 'Phường Bến Thành', 'WARD', 'BTH', 2),
(8, 'Phường Đa Kao', 'WARD', 'DK', 2);

SELECT setval('khu_vuc_hanh_chinh_ma_khu_vuc_seq', 8);

-- 4. Table properties
CREATE TABLE tai_san_cho_thue (
    ma_ban_ghi BIGSERIAL PRIMARY KEY,
    ma_ben_cho_thue BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    ten_hien_thi VARCHAR(255) NOT NULL,
    mo_ta TEXT,
    dia_chi VARCHAR(255) NOT NULL,
    ma_tinh_thanh BIGINT NOT NULL REFERENCES khu_vuc_hanh_chinh(ma_khu_vuc),
    ma_quan_huyen BIGINT NOT NULL REFERENCES khu_vuc_hanh_chinh(ma_khu_vuc),
    ma_phuong_xa BIGINT NOT NULL REFERENCES khu_vuc_hanh_chinh(ma_khu_vuc),
    don_gia_dien DECIMAL(10,2),
    don_gia_nuoc DECIMAL(10,2),
    trang_thai VARCHAR(50) DEFAULT 'ACTIVE',
    loai_tai_san VARCHAR(50) DEFAULT 'BOARDING_HOUSE',
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    thoi_diem_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_properties_landlord_id ON tai_san_cho_thue(ma_ben_cho_thue);

-- 5. Table rooms
CREATE TABLE phong_cho_thue (
    ma_ban_ghi BIGSERIAL PRIMARY KEY,
    ma_tai_san BIGINT NOT NULL REFERENCES tai_san_cho_thue(ma_ban_ghi),
    ten_hien_thi VARCHAR(255) NOT NULL,
    dien_tich DOUBLE PRECISION NOT NULL,
    gia DECIMAL(12,2) NOT NULL,
    suc_chua_toi_da INT NOT NULL,
    trang_thai VARCHAR(50) DEFAULT 'AVAILABLE',
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    thoi_diem_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rooms_property_id ON phong_cho_thue(ma_tai_san);

-- 6. Table property_images
CREATE TABLE hinh_anh_tai_san (
    ma_ban_ghi BIGSERIAL PRIMARY KEY,
    ma_tai_san BIGINT NOT NULL REFERENCES tai_san_cho_thue(ma_ban_ghi) ON DELETE CASCADE,
    duong_dan_hinh_anh VARCHAR(500) NOT NULL,
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_property_images_property_id ON hinh_anh_tai_san(ma_tai_san);

-- 7. Table favorite_properties
CREATE TABLE tai_san_yeu_thich (
    ma_ban_ghi         BIGSERIAL PRIMARY KEY,
    ma_nguoi_dung    BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung) ON DELETE CASCADE,
    ma_tai_san BIGINT NOT NULL REFERENCES tai_san_cho_thue(ma_ban_ghi) ON DELETE CASCADE,
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_property UNIQUE (ma_nguoi_dung, ma_tai_san)
);

CREATE INDEX idx_favorites_user_id     ON tai_san_yeu_thich(ma_nguoi_dung);
CREATE INDEX idx_favorites_property_id ON tai_san_yeu_thich(ma_tai_san);

-- 8. Table listings (PostGIS)
CREATE TABLE tin_cho_thue (
    ma_tin_dang BIGSERIAL PRIMARY KEY,
    ma_chu_tin BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    ma_khu_vuc BIGINT NOT NULL REFERENCES khu_vuc_hanh_chinh(ma_khu_vuc),
    ma_nguoi_duyet BIGINT REFERENCES nguoi_dung(ma_nguoi_dung),
    tieu_de VARCHAR(200) NOT NULL,
    mo_ta TEXT,
    loai_tin_dang VARCHAR(15) NOT NULL CHECK (loai_tin_dang IN ('WHOLE_HOUSE', 'BOARDING_ROOM', 'SHARED_ROOM')),
    gia_cho_thue DECIMAL(12,2) NOT NULL,
    dien_tich_met_vuong DECIMAL(6,2),
    dia_chi VARCHAR(255),
    toa_do_vi_tri geometry(POINT, 4326), -- Hệ tọa độ WGS 84
    trang_thai_kiem_duyet VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK (trang_thai_kiem_duyet IN ('PENDING', 'APPROVED', 'REJECTED')),
    trang_thai_cho_thue VARCHAR(15) NOT NULL DEFAULT 'AVAILABLE' CHECK (trang_thai_cho_thue IN ('AVAILABLE', 'RENTED')),
    ly_do_tu_choi VARCHAR(255),
    la_tin_uu_tien BOOLEAN DEFAULT FALSE,
    han_tin_uu_tien TIMESTAMP,
    thoi_diem_lam_moi_tin TIMESTAMP,
    so_luot_xem INT DEFAULT 0,
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    thoi_diem_cap_nhat TIMESTAMP
);

CREATE INDEX idx_listings_area_id ON tin_cho_thue(ma_khu_vuc);
CREATE INDEX idx_listings_owner_id ON tin_cho_thue(ma_chu_tin);
CREATE INDEX idx_listings_status ON tin_cho_thue(trang_thai_kiem_duyet);
CREATE INDEX idx_listings_location ON tin_cho_thue USING GIST (toa_do_vi_tri);

-- 9. Table listing_images
CREATE TABLE hinh_anh_tin_dang (
    ma_hinh_anh BIGSERIAL PRIMARY KEY,
    ma_tin_dang BIGINT NOT NULL REFERENCES tin_cho_thue(ma_tin_dang) ON DELETE CASCADE,
    duong_dan_hinh_anh VARCHAR(255) NOT NULL,
    la_anh_dai_dien BOOLEAN DEFAULT FALSE,
    thu_tu_hien_thi SMALLINT DEFAULT 0
);

-- 13. Table contracts
CREATE TABLE hop_dong_thue (
    ma_hop_dong BIGSERIAL PRIMARY KEY,
    ma_tin_dang BIGINT NOT NULL REFERENCES tin_cho_thue(ma_tin_dang),
    ma_ben_cho_thue BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    ma_ben_thue BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    ngay_bat_dau DATE NOT NULL,
    ngay_ket_thuc DATE NOT NULL,
    tien_thue_moi_thang DECIMAL(12,2) NOT NULL,
    tien_dat_coc DECIMAL(12,2),
    trang_thai VARCHAR(15) NOT NULL DEFAULT 'ACTIVE' CHECK (trang_thai IN ('ACTIVE', 'EXPIRED', 'TERMINATED')),
    duong_dan_tep_hop_dong VARCHAR(255),
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. Table membership_packages
CREATE TABLE goi_dich_vu (
    ma_goi_dich_vu SMALLSERIAL PRIMARY KEY,
    ten_goi_dich_vu VARCHAR(20) NOT NULL,
    gia DECIMAL(10,2) NOT NULL DEFAULT 0,
    han_muc_tin_thuong SMALLINT NOT NULL,
    han_muc_tin_uu_tien SMALLINT NOT NULL DEFAULT 0,
    han_muc_lam_moi SMALLINT NOT NULL DEFAULT 0,
    mo_ta VARCHAR(255)
);

-- 15. Table user_subscriptions
CREATE TABLE dang_ky_goi_dich_vu (
    ma_dang_ky_goi BIGSERIAL PRIMARY KEY,
    ma_nguoi_dung BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    ma_goi_dich_vu SMALLINT NOT NULL REFERENCES goi_dich_vu(ma_goi_dich_vu),
    thoi_diem_mua_goi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    luot_tin_thuong_con_lai SMALLINT,
    luot_tin_uu_tien_con_lai SMALLINT,
    luot_lam_moi_con_lai SMALLINT,
    moc_dat_lai_han_muc TIMESTAMP,
    trang_thai VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (trang_thai IN ('ACTIVE', 'EXPIRED'))
);

-- 16. Table payment_transactions
CREATE TABLE giao_dich_thanh_toan (
    ma_giao_dich BIGSERIAL PRIMARY KEY,
    ma_nguoi_dung BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    ma_dang_ky_goi BIGINT UNIQUE REFERENCES dang_ky_goi_dich_vu(ma_dang_ky_goi),
    so_tien DECIMAL(12,2) NOT NULL,
    phuong_thuc_thanh_toan VARCHAR(20) DEFAULT 'VNPAY',
    tham_chieu_giao_dich_vnpay VARCHAR(100),
    trang_thai VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK (trang_thai IN ('PENDING', 'SUCCESS', 'FAILED')),
    thoi_diem_giao_dich TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 17. Table notifications
CREATE TABLE thong_bao (
    ma_thong_bao BIGSERIAL PRIMARY KEY,
    ma_nguoi_dung BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    loai_thong_bao VARCHAR(30) NOT NULL,
    tieu_de VARCHAR(150),
    noi_dung VARCHAR(500),
    ma_tin_dang BIGINT REFERENCES tin_cho_thue(ma_tin_dang),
    ma_hop_dong BIGINT REFERENCES hop_dong_thue(ma_hop_dong),
    da_doc BOOLEAN DEFAULT FALSE,
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add advanced details to listings
-- V5: Add advanced detail columns to listings table for multi-step property creation flow
-- These fields support both "Whole House" (Nhà ở) and "Room" (Phòng trọ) listing types.
-- House-specific fields are nullable so Room listings can omit them.

ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS loai_hinh_nha       VARCHAR(50);   -- MAT_PHO | NGO_HEM | BIET_THU | LIEN_KE
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS so_phong_ngu         INT;           -- Number of bedrooms
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS so_phong_tam        INT;           -- Number of bathrooms
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS tong_so_tang     INT;           -- Total number of floors
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS huong_cua   VARCHAR(50);   -- NORTH | SOUTH | EAST | WEST | NORTHEAST | ...
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS giay_to_phap_ly  VARCHAR(100);  -- PINK_BOOK | RED_BOOK | SALE_CONTRACT | NONE
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS tinh_trang_noi_that VARCHAR(50);   -- FULL | BASIC | EMPTY
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS tien_dat_coc   DECIMAL(12,2); -- Security deposit amount
ALTER TABLE tin_cho_thue ADD COLUMN IF NOT EXISTS loai_nguoi_dang      VARCHAR(20);   -- CA_NHAN (private owner) | MOI_GIOI (broker)

COMMENT ON COLUMN tin_cho_thue.loai_hinh_nha IS 'Loại nhà: MAT_PHO (mặt phố), NGO_HEM (ngõ hẻm), BIET_THU (biệt thự), LIEN_KE (liền kề)';
COMMENT ON COLUMN tin_cho_thue.so_phong_ngu IS 'Số phòng ngủ';
COMMENT ON COLUMN tin_cho_thue.so_phong_tam IS 'Số phòng tắm / vệ sinh';
COMMENT ON COLUMN tin_cho_thue.tong_so_tang IS 'Tổng số tầng của toà nhà';
COMMENT ON COLUMN tin_cho_thue.huong_cua IS 'Hướng cửa chính: NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST';
COMMENT ON COLUMN tin_cho_thue.giay_to_phap_ly IS 'Giấy tờ pháp lý: PINK_BOOK, RED_BOOK, SALE_CONTRACT, NONE';
COMMENT ON COLUMN tin_cho_thue.tinh_trang_noi_that IS 'Tình trạng nội thất: FULL (đầy đủ), BASIC (cơ bản), EMPTY (không có)';
COMMENT ON COLUMN tin_cho_thue.tien_dat_coc IS 'Tiền đặt cọc (VND)';
COMMENT ON COLUMN tin_cho_thue.loai_nguoi_dang IS 'Loại người đăng: CA_NHAN (cá nhân), MOI_GIOI (môi giới)';

-- seed membership packages
INSERT INTO goi_dich_vu (ten_goi_dich_vu, gia, han_muc_tin_thuong, han_muc_tin_uu_tien, han_muc_lam_moi, mo_ta) VALUES
('Gói Cơ Bản', 0, 3, 0, 0, 'Phù hợp cho người dùng cá nhân có nhu cầu đăng tin thỉnh thoảng.'),
('Gói Tiêu Chuẩn', 50000, 10, 0, 5, 'Dành cho môi giới vừa và nhỏ, cần đăng nhiều tin hơn.'),
('Gói VIP', 150000, 30, 5, 20, 'Gói ưu đãi cao cấp giúp tin của bạn nổi bật hơn (Tin VIP) và thêm nhiều lượt đẩy tin lên top.');

-- create user favorites
-- Reconstructed from the existing development database's legacy V7 schema.
-- Idempotent for databases where this table was created before the source was retained.
CREATE TABLE IF NOT EXISTS tin_yeu_thich (
    ma_ban_ghi BIGSERIAL PRIMARY KEY,
    ma_nguoi_dung BIGINT NOT NULL,
    ma_tin_dang BIGINT NOT NULL,
    thoi_diem_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_favorites_user_listing UNIQUE (ma_nguoi_dung, ma_tin_dang),
    CONSTRAINT fk_user_favorites_user FOREIGN KEY (ma_nguoi_dung) REFERENCES nguoi_dung(ma_nguoi_dung) ON DELETE CASCADE,
    CONSTRAINT fk_user_favorites_listing FOREIGN KEY (ma_tin_dang) REFERENCES tin_cho_thue(ma_tin_dang) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON tin_yeu_thich(ma_nguoi_dung);
CREATE INDEX IF NOT EXISTS idx_user_favorites_listing_id ON tin_yeu_thich(ma_tin_dang);

-- listing management statuses
-- Keep listings referenced by contracts when their owner removes them.
ALTER TABLE tin_cho_thue DROP CONSTRAINT IF EXISTS tin_cho_thue_trang_thai_cho_thue_check;
ALTER TABLE tin_cho_thue ADD CONSTRAINT tin_cho_thue_trang_thai_cho_thue_check
    CHECK (trang_thai_cho_thue IN ('AVAILABLE', 'RENTED', 'HIDDEN', 'DELETED'));
CREATE INDEX IF NOT EXISTS idx_listings_owner_created ON tin_cho_thue(ma_chu_tin, thoi_diem_tao DESC);

-- repair seed area names utf8
-- Repair legacy seed names whose Vietnamese characters were replaced during import.
-- Match seed identity and only update damaged text, preserving custom area names.
UPDATE khu_vuc_hanh_chinh AS dien_tich
SET ten_khu_vuc = seed.correct_name
FROM (VALUES
    (1::bigint, 'PROVINCE', 'SG', 'Thành phố Hồ Chí Minh'),
    (2::bigint, 'DISTRICT', 'Q1', 'Quận 1'),
    (3::bigint, 'DISTRICT', 'Q7', 'Quận 7'),
    (4::bigint, 'DISTRICT', 'TD', 'Thành phố Thủ Đức'),
    (5::bigint, 'DISTRICT', 'BT', 'Quận Bình Thạnh'),
    (6::bigint, 'WARD', 'BN', 'Phường Bến Nghé'),
    (7::bigint, 'WARD', 'BTH', 'Phường Bến Thành'),
    (8::bigint, 'WARD', 'DK', 'Phường Đa Kao')
) AS seed(ma_khu_vuc, cap_hanh_chinh, ma_quan_ly, correct_name)
WHERE dien_tich.ma_khu_vuc = seed.ma_khu_vuc
  AND dien_tich.cap_hanh_chinh = seed.cap_hanh_chinh
  AND dien_tich.ma_quan_ly = seed.ma_quan_ly
  AND (position('?' IN dien_tich.ten_khu_vuc) > 0
       OR position(U&'\FFFD' IN dien_tich.ten_khu_vuc) > 0);

-- hcm post merger commune level areas
-- TP.HCM: 168 commune-level units under Resolution 1685/NQ-UBTVQH15 (2025-06-16).
-- Source: https://xaydungchinhsach.chinhphu.vn/sap-xep-dvhc-danh-sach-168-xa-phuong-dac-khu-cua-thanh-pho-ho-chi-minh-119250623085031865.htm
-- HCM25-* are stable application identifiers, NOT official administrative codes.
-- Keep legacy districts/wards and references unchanged. New units are province children.
ALTER TABLE tai_san_cho_thue ALTER COLUMN ma_quan_huyen DROP NOT NULL;

WITH units(ma_quan_ly, ten_khu_vuc, cap_hanh_chinh) AS (VALUES
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
INSERT INTO khu_vuc_hanh_chinh (ten_khu_vuc, cap_hanh_chinh, ma_quan_ly, ma_khu_vuc_cap_tren)
SELECT u.ten_khu_vuc, u.cap_hanh_chinh, u.ma_quan_ly, p.ma_khu_vuc
FROM units u CROSS JOIN khu_vuc_hanh_chinh p
WHERE p.cap_hanh_chinh = 'PROVINCE' AND p.ma_quan_ly = 'SG'
  AND NOT EXISTS (SELECT 1 FROM khu_vuc_hanh_chinh a WHERE a.ma_khu_vuc_cap_tren = p.ma_khu_vuc AND a.ma_quan_ly = u.ma_quan_ly);

-- contract management
-- Keep existing leases and IDs. New contracts are drafts until tenant acceptance.
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS ghi_chu VARCHAR(2000);
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS phien_ban_du_lieu BIGINT NOT NULL DEFAULT 0;
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS tieu_de_tin_trong_hop_dong VARCHAR(255);
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS dia_chi_tin_trong_hop_dong VARCHAR(255);
UPDATE hop_dong_thue c SET tieu_de_tin_trong_hop_dong=l.tieu_de, dia_chi_tin_trong_hop_dong=l.dia_chi FROM tin_cho_thue l
    WHERE l.ma_tin_dang=c.ma_tin_dang AND c.tieu_de_tin_trong_hop_dong IS NULL;
ALTER TABLE hop_dong_thue DROP CONSTRAINT IF EXISTS hop_dong_thue_trang_thai_check;
ALTER TABLE hop_dong_thue ADD CONSTRAINT hop_dong_thue_trang_thai_check
    CHECK (trang_thai IN ('DRAFT','ACTIVE','EXPIRED','TERMINATED','CANCELLED'));
ALTER TABLE hop_dong_thue ALTER COLUMN trang_thai SET DEFAULT 'DRAFT';
ALTER TABLE hop_dong_thue ADD CONSTRAINT hop_dong_thue_dates_check CHECK (ngay_ket_thuc > ngay_bat_dau) NOT VALID;
ALTER TABLE hop_dong_thue ADD CONSTRAINT hop_dong_thue_money_check CHECK (tien_thue_moi_thang > 0 AND tien_dat_coc >= 0) NOT VALID;
CREATE INDEX IF NOT EXISTS idx_contracts_listing_status ON hop_dong_thue(ma_tin_dang, trang_thai);

-- contract templates
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS loai_hop_dong VARCHAR(20);
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS chi_tiet_dang_json TEXT;
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS noi_dung_hop_dong TEXT;
ALTER TABLE hop_dong_thue ADD COLUMN IF NOT EXISTS thoi_diem_xac_nhan TIMESTAMP;

-- rename membership packages
UPDATE goi_dich_vu
SET ten_goi_dich_vu = 'Gói PLUS'
WHERE LOWER(TRIM(ten_goi_dich_vu)) IN ('gói tiêu chuẩn', 'tiêu chuẩn');

UPDATE goi_dich_vu
SET ten_goi_dich_vu = 'Gói PRO'
WHERE LOWER(TRIM(ten_goi_dich_vu)) IN ('gói vip', 'vip');

-- shared room details
ALTER TABLE tin_cho_thue
    ADD COLUMN so_nguoi_dang_o INTEGER,
    ADD COLUMN so_nguoi_o_toi_da INTEGER,
    ADD COLUMN yeu_cau_gioi_tinh_nguoi_o VARCHAR(20),
    ADD COLUMN cho_phep_nuoi_thu_cung BOOLEAN,
    ADD COLUMN cho_phep_hut_thuoc BOOLEAN,
    ADD COLUMN yeu_cau_nguoi_o_ghep VARCHAR(500);

UPDATE tin_cho_thue SET so_nguoi_dang_o = 1, so_nguoi_o_toi_da = 2,
    yeu_cau_gioi_tinh_nguoi_o = 'ANY', cho_phep_nuoi_thu_cung = FALSE, cho_phep_hut_thuoc = FALSE
WHERE loai_tin_dang = 'SHARED_ROOM';

ALTER TABLE tin_cho_thue ADD CONSTRAINT valid_shared_room_details CHECK (
    loai_tin_dang <> 'SHARED_ROOM' OR (
        so_nguoi_dang_o IS NOT NULL AND so_nguoi_o_toi_da IS NOT NULL
        AND so_nguoi_dang_o >= 0 AND so_nguoi_o_toi_da <= 20
        AND so_nguoi_o_toi_da > so_nguoi_dang_o
        AND yeu_cau_gioi_tinh_nguoi_o IS NOT NULL AND yeu_cau_gioi_tinh_nguoi_o IN ('ANY', 'MALE', 'FEMALE')
    )
);

-- user personal interests
CREATE TABLE so_thich_da_chon (
    ma_ho_so_so_thich BIGINT NOT NULL REFERENCES so_thich_nguoi_dung(ma_ho_so_so_thich) ON DELETE CASCADE,
    ma_so_thich VARCHAR(32) NOT NULL,
    PRIMARY KEY (ma_ho_so_so_thich, ma_so_thich),
    CONSTRAINT valid_personal_interest CHECK (ma_so_thich IN (
        'CAT_LOVER', 'DOG_LOVER', 'PLANTS', 'QUIET', 'TIDY', 'STUDY', 'EARLY_BIRD', 'NIGHT_OWL', 'NON_SMOKER', 'SOCIABLE', 'MUSIC', 'MOVIES', 'READING', 'GAMING', 'COOKING', 'SPORTS', 'TRAVEL', 'COFFEE'
    ))
);

-- notification indexes
UPDATE thong_bao SET da_doc = FALSE WHERE da_doc IS NULL;
ALTER TABLE thong_bao ALTER COLUMN da_doc SET NOT NULL;
CREATE INDEX idx_notifications_user_created ON thong_bao(ma_nguoi_dung, thoi_diem_tao DESC, ma_thong_bao DESC);
CREATE INDEX idx_notifications_user_unread ON thong_bao(ma_nguoi_dung) WHERE da_doc = FALSE;

-- merge user roles into member
ALTER TABLE nguoi_dung DROP CONSTRAINT nguoi_dung_vai_tro_check;

UPDATE nguoi_dung SET vai_tro = 'MEMBER' WHERE vai_tro IN ('USER', 'OWNER');

ALTER TABLE nguoi_dung ADD CONSTRAINT nguoi_dung_vai_tro_check CHECK (vai_tro IN ('MEMBER', 'ADMIN'));

-- administrative area status
ALTER TABLE khu_vuc_hanh_chinh ADD COLUMN dang_su_dung BOOLEAN NOT NULL DEFAULT TRUE;
CREATE INDEX idx_areas_parent_active ON khu_vuc_hanh_chinh(ma_khu_vuc_cap_tren, dang_su_dung);

-- system content
CREATE TABLE noi_dung_he_thong (
    ma_duong_dan_trang VARCHAR(20) PRIMARY KEY CHECK (ma_duong_dan_trang IN ('about','rules','guide','contact','support')),
    tieu_de VARCHAR(150) NOT NULL,
    noi_dung_ban_nhap TEXT NOT NULL,
    tieu_de_cong_khai VARCHAR(150),
    noi_dung_cong_khai TEXT,
    da_xuat_ban BOOLEAN NOT NULL DEFAULT FALSE,
    thoi_diem_xuat_ban TIMESTAMP,
    thoi_diem_cap_nhat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    phien_ban_du_lieu BIGINT NOT NULL DEFAULT 0,
    CHECK (NOT da_xuat_ban OR (tieu_de_cong_khai IS NOT NULL AND noi_dung_cong_khai IS NOT NULL AND thoi_diem_xuat_ban IS NOT NULL))
);

WITH initial(ma_duong_dan_trang, tieu_de, noi_dung_ban_nhap) AS (VALUES
    ('about', 'Giới thiệu', 'Ứng dụng kết nối người thuê và người cho thuê tại TP.HCM, hỗ trợ đăng tin, tìm nhà trên bản đồ và quản lý hợp đồng.'),
    ('rules', 'Quy định đăng tin', 'Cung cấp đúng địa chỉ, giá thuê và ảnh thực tế. Tin mới và tin chỉnh sửa phải được Admin duyệt trước khi xuất hiện công khai.'),
    ('guide', 'Hướng dẫn sử dụng', E'1. Chọn Đăng Tin và điền thông tin nhà hoặc phòng.\n2. Gửi tin để Admin duyệt.\n3. Xem trạng thái trong Quản Lý Tin Đăng.\n4. Tìm nhà đã duyệt ở mục Thuê Nhà, Thuê Phòng Trọ, Tìm Ở Ghép hoặc Bản Đồ.'),
    ('contact', 'Liên hệ', 'Thông tin liên hệ hỗ trợ sẽ được cập nhật khi hệ thống chính thức triển khai.'),
    ('support', 'Báo cáo sự cố', 'Ghi lại thao tác gặp lỗi và ảnh màn hình, sau đó gửi cho người quản trị theo thông tin ở mục Liên hệ. Chức năng gửi báo cáo trực tiếp trong ứng dụng chưa được kết nối.')
)
INSERT INTO noi_dung_he_thong (ma_duong_dan_trang, tieu_de, noi_dung_ban_nhap, tieu_de_cong_khai, noi_dung_cong_khai, da_xuat_ban, thoi_diem_xuat_ban)
SELECT ma_duong_dan_trang, tieu_de, noi_dung_ban_nhap, tieu_de, noi_dung_ban_nhap, TRUE, CURRENT_TIMESTAMP FROM initial;

-- password version
ALTER TABLE nguoi_dung ADD COLUMN phien_ban_mat_khau INTEGER NOT NULL DEFAULT 0;

-- incident reports
CREATE TABLE bao_cao_su_co (
    ma_ban_ghi BIGSERIAL PRIMARY KEY,
    ma_nguoi_bao_su_co BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    khoa_doi_chieu_yeu_cau VARCHAR(80) NOT NULL,
    tieu_de VARCHAR(150) NOT NULL,
    nhom_phan_loai VARCHAR(20) NOT NULL CHECK (nhom_phan_loai IN ('ACCOUNT','LISTING','CONTRACT','PAYMENT','TECHNICAL','OTHER')),
    mo_ta VARCHAR(5000) NOT NULL,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (trang_thai IN ('OPEN','IN_PROGRESS','RESOLVED','REJECTED')),
    thoi_diem_tao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    thoi_diem_cap_nhat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    phien_ban_du_lieu BIGINT NOT NULL DEFAULT 0,
    UNIQUE (ma_nguoi_bao_su_co, khoa_doi_chieu_yeu_cau)
);
CREATE TABLE lich_su_xu_ly_su_co (
    ma_ban_ghi BIGSERIAL PRIMARY KEY,
    ma_bao_cao_su_co BIGINT NOT NULL REFERENCES bao_cao_su_co(ma_ban_ghi),
    ma_nguoi_xu_ly BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung),
    trang_thai VARCHAR(20) NOT NULL CHECK (trang_thai IN ('OPEN','IN_PROGRESS','RESOLVED','REJECTED')),
    noi_dung_thong_diep VARCHAR(2000) NOT NULL,
    thoi_diem_tao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_incidents_reporter_created ON bao_cao_su_co(ma_nguoi_bao_su_co, thoi_diem_tao DESC);
CREATE INDEX idx_incidents_status_updated ON bao_cao_su_co(trang_thai, thoi_diem_cap_nhat DESC, ma_ban_ghi DESC);
CREATE INDEX idx_incident_updates_report ON lich_su_xu_ly_su_co(ma_bao_cao_su_co, thoi_diem_tao, ma_ban_ghi);
ALTER TABLE thong_bao ADD COLUMN ma_bao_cao_su_co BIGINT REFERENCES bao_cao_su_co(ma_ban_ghi);

-- admin membership packages
ALTER TABLE goi_dich_vu ADD COLUMN dang_su_dung BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE goi_dich_vu ADD COLUMN phien_ban_du_lieu BIGINT NOT NULL DEFAULT 0;
CREATE UNIQUE INDEX idx_membership_package_name_unique ON goi_dich_vu(lower(ten_goi_dich_vu));
ALTER TABLE dang_ky_goi_dich_vu ADD COLUMN ten_goi_tai_thoi_diem_mua VARCHAR(20);
UPDATE dang_ky_goi_dich_vu s SET ten_goi_tai_thoi_diem_mua = p.ten_goi_dich_vu FROM goi_dich_vu p WHERE s.ma_goi_dich_vu = p.ma_goi_dich_vu;
ALTER TABLE dang_ky_goi_dich_vu ALTER COLUMN luot_tin_thuong_con_lai TYPE INTEGER;
ALTER TABLE dang_ky_goi_dich_vu ALTER COLUMN luot_tin_uu_tien_con_lai TYPE INTEGER;
ALTER TABLE dang_ky_goi_dich_vu ALTER COLUMN luot_lam_moi_con_lai TYPE INTEGER;
ALTER TABLE giao_dich_thanh_toan ADD COLUMN ma_goi_dich_vu SMALLINT REFERENCES goi_dich_vu(ma_goi_dich_vu);
ALTER TABLE giao_dich_thanh_toan ADD COLUMN ten_goi_tai_thoi_diem_mua VARCHAR(20);
ALTER TABLE giao_dich_thanh_toan ADD COLUMN han_muc_tin_thuong_khi_mua SMALLINT;
ALTER TABLE giao_dich_thanh_toan ADD COLUMN han_muc_tin_uu_tien_khi_mua SMALLINT;
ALTER TABLE giao_dich_thanh_toan ADD COLUMN han_muc_lam_moi_khi_mua SMALLINT;
UPDATE giao_dich_thanh_toan t SET ma_goi_dich_vu=p.ma_goi_dich_vu, ten_goi_tai_thoi_diem_mua=p.ten_goi_dich_vu,
    han_muc_tin_thuong_khi_mua=p.han_muc_tin_thuong, han_muc_tin_uu_tien_khi_mua=p.han_muc_tin_uu_tien, han_muc_lam_moi_khi_mua=p.han_muc_lam_moi
FROM goi_dich_vu p WHERE split_part(t.tham_chieu_giao_dich_vnpay, '_', 1) = p.ma_goi_dich_vu::text;
CREATE INDEX idx_payments_package_id ON giao_dich_thanh_toan(ma_goi_dich_vu);

-- nearby listing index
CREATE INDEX IF NOT EXISTS idx_listings_available_geography
ON tin_cho_thue USING GIST ((CAST(toa_do_vi_tri AS geography)))
WHERE toa_do_vi_tri IS NOT NULL AND trang_thai_kiem_duyet = 'APPROVED' AND trang_thai_cho_thue = 'AVAILABLE';

-- default membership
ALTER TABLE goi_dich_vu ADD COLUMN la_goi_mac_dinh BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO goi_dich_vu (ten_goi_dich_vu, gia, han_muc_tin_thuong, han_muc_tin_uu_tien, han_muc_lam_moi, mo_ta, dang_su_dung, phien_ban_du_lieu)
SELECT 'Gói Cơ Bản', 0, 3, 0, 0, 'Gói mặc định cho tài khoản Member.', TRUE, 0
WHERE NOT EXISTS (SELECT 1 FROM goi_dich_vu WHERE gia = 0);

UPDATE goi_dich_vu SET la_goi_mac_dinh = TRUE, dang_su_dung = TRUE
WHERE ma_goi_dich_vu = (SELECT ma_goi_dich_vu FROM goi_dich_vu WHERE gia = 0 ORDER BY ma_goi_dich_vu LIMIT 1);

CREATE UNIQUE INDEX idx_membership_default_unique ON goi_dich_vu (la_goi_mac_dinh) WHERE la_goi_mac_dinh = TRUE;
ALTER TABLE goi_dich_vu ADD CONSTRAINT ck_default_membership_free_active CHECK (NOT la_goi_mac_dinh OR (gia = 0 AND dang_su_dung = TRUE));
CREATE UNIQUE INDEX idx_user_subscription_unique ON dang_ky_goi_dich_vu (ma_nguoi_dung);

INSERT INTO dang_ky_goi_dich_vu (ma_nguoi_dung, ma_goi_dich_vu, thoi_diem_mua_goi, luot_tin_thuong_con_lai, luot_tin_uu_tien_con_lai,
    luot_lam_moi_con_lai, moc_dat_lai_han_muc, trang_thai, ten_goi_tai_thoi_diem_mua)
SELECT u.ma_nguoi_dung, p.ma_goi_dich_vu, CURRENT_TIMESTAMP, p.han_muc_tin_thuong, p.han_muc_tin_uu_tien, p.han_muc_lam_moi,
    NULL, 'ACTIVE', p.ten_goi_dich_vu
FROM nguoi_dung u CROSS JOIN goi_dich_vu p
WHERE p.la_goi_mac_dinh = TRUE AND u.vai_tro = 'MEMBER' AND u.da_xac_thuc_thu_dien_tu = TRUE AND u.trang_thai = 'ACTIVE'
    AND NOT EXISTS (SELECT 1 FROM dang_ky_goi_dich_vu s WHERE s.ma_nguoi_dung = u.ma_nguoi_dung);

-- amenities
CREATE TABLE danh_muc_tien_ich (
    ma_tien_ich BIGSERIAL PRIMARY KEY,
    ten_hien_thi VARCHAR(100) NOT NULL,
    nhom_phan_loai VARCHAR(20) NOT NULL CHECK (nhom_phan_loai IN ('FURNITURE', 'UTILITY')),
    mo_ta VARCHAR(255) NOT NULL DEFAULT '',
    dang_su_dung BOOLEAN NOT NULL DEFAULT TRUE,
    phien_ban_du_lieu BIGINT NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX idx_amenity_category_name ON danh_muc_tien_ich(nhom_phan_loai, lower(ten_hien_thi));

CREATE TABLE tien_ich_cua_tin_dang (
    ma_tin_dang BIGINT NOT NULL REFERENCES tin_cho_thue(ma_tin_dang) ON DELETE CASCADE,
    ma_tien_ich BIGINT NOT NULL REFERENCES danh_muc_tien_ich(ma_tien_ich),
    PRIMARY KEY (ma_tin_dang, ma_tien_ich)
);
CREATE INDEX idx_listing_amenities_amenity ON tien_ich_cua_tin_dang(ma_tien_ich);

INSERT INTO danh_muc_tien_ich(ten_hien_thi, nhom_phan_loai) VALUES
('Giường', 'FURNITURE'), ('Tủ quần áo', 'FURNITURE'),
('Bàn ghế', 'FURNITURE'), ('Máy lạnh', 'FURNITURE'),
('Tủ lạnh', 'FURNITURE'), ('Máy giặt', 'FURNITURE'),
('Bếp nấu ăn', 'FURNITURE'), ('Máy nước nóng', 'FURNITURE'),
('Wi-Fi', 'UTILITY'), ('Chỗ để xe', 'UTILITY'),
('Thang máy', 'UTILITY'), ('Ban công', 'UTILITY'),
('Nhà vệ sinh riêng', 'UTILITY'), ('Camera an ninh', 'UTILITY');

-- vnpay payment results
ALTER TABLE giao_dich_thanh_toan ADD COLUMN ma_ket_qua_vnpay VARCHAR(2);
CREATE INDEX idx_payment_user_date ON giao_dich_thanh_toan (ma_nguoi_dung, thoi_diem_giao_dich DESC);

-- admin qr login
CREATE TABLE phien_dang_nhap_qr_quan_tri (
    ma_ban_ghi VARCHAR(36) PRIMARY KEY,
    bam_bi_mat_trinh_duyet VARCHAR(64) NOT NULL,
    bam_bi_mat_quet_qr VARCHAR(64) NOT NULL,
    ma_xac_thuc VARCHAR(6) NOT NULL,
    ten_trinh_duyet VARCHAR(80) NOT NULL,
    dia_chi_trang_web VARCHAR(200) NOT NULL,
    bam_bang_chung_ben_yeu_cau VARCHAR(64) NOT NULL,
    trang_thai VARCHAR(12) NOT NULL DEFAULT 'PENDING'
        CHECK (trang_thai IN ('PENDING','SCANNED','APPROVED','REJECTED','CANCELLED','CONSUMED')),
    ma_quan_tri_vien BIGINT REFERENCES nguoi_dung(ma_nguoi_dung),
    phien_ban_mat_khau INTEGER,
    thoi_diem_tao TIMESTAMPTZ NOT NULL,
    thoi_diem_het_han TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_admin_qr_expiry ON phien_dang_nhap_qr_quan_tri(thoi_diem_het_han);
CREATE INDEX idx_admin_qr_requester ON phien_dang_nhap_qr_quan_tri(bam_bang_chung_ben_yeu_cau, thoi_diem_tao);

-- chat history
CREATE TABLE lich_su_tro_chuyen (
    ma_ban_ghi BIGSERIAL PRIMARY KEY,
    ma_nguoi_dung BIGINT NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung) ON DELETE CASCADE,
    yeu_cau_hoi_thoai_json TEXT NOT NULL,
    phan_hoi_hoi_thoai_json TEXT NOT NULL,
    thoi_diem_tao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chatbot_history_user_id ON lich_su_tro_chuyen(ma_nguoi_dung, ma_ban_ghi DESC);

-- refresh default help content
WITH replacement(ma_duong_dan_trang, old_body, new_body) AS (VALUES
    ('about', 'Ứng dụng kết nối người thuê và người cho thuê tại TP.HCM, hỗ trợ đăng tin, tìm nhà trên bản đồ và quản lý hợp đồng.', $article$<h2>Một nơi ở phù hợp, một trải nghiệm dễ dàng</h2><p>Rental kết nối người tìm nhà, phòng trọ và người ở ghép với các tin cho thuê được công bố trong hệ thống.</p><h3>Dành cho người tìm nơi ở</h3><ul><li>Tìm kiếm theo khu vực, giá thuê, diện tích và tiện ích.</li><li>Xem bản đồ, tìm quanh một vị trí và lưu những tin yêu thích.</li><li>Trao đổi với trợ lý tìm nhà chạy nội bộ theo các điều kiện bạn cung cấp.</li></ul><h3>Dành cho người cho thuê</h3><ul><li>Đăng tin, cập nhật trạng thái còn trống hoặc đã cho thuê.</li><li>Theo dõi quá trình duyệt tin và quản lý hợp đồng của tài khoản.</li><li>Xem các gói dịch vụ và quyền lợi phù hợp với nhu cầu.</li></ul><p>Các tin phải được duyệt trước khi xuất hiện công khai. Bạn nên kiểm tra thông tin thực tế và trao đổi rõ với bên cho thuê trước khi quyết định.</p>$article$),
    ('rules', 'Cung cấp đúng địa chỉ, giá thuê và ảnh thực tế. Tin mới và tin chỉnh sửa phải được Admin duyệt trước khi xuất hiện công khai.', $article$<h2>Cùng giữ thông tin rõ ràng và đáng tin cậy</h2><h3>Thông tin tin đăng</h3><ul><li>Sử dụng tiêu đề, địa chỉ, giá thuê, diện tích và hình ảnh phản ánh đúng thực tế.</li><li>Chỉ đăng nội dung mà bạn có quyền cung cấp. Không đưa thông tin cá nhân của người khác lên tin khi chưa được đồng ý.</li><li>Không đăng nội dung giả mạo, xúc phạm, gây hiểu nhầm hoặc không liên quan đến nhu cầu thuê và cho thuê.</li></ul><h3>Kiểm duyệt và cập nhật</h3><p>Tin mới và tin chỉnh sửa phải chờ Admin duyệt. Khi không còn nhu cầu cho thuê, hãy ẩn tin hoặc đánh dấu đã cho thuê trong Quản lý tin đăng.</p><h3>Sử dụng tài khoản</h3><p>Giữ kín mật khẩu và mã xác thực. Chỉ sử dụng các quyền được cấp cho tài khoản của mình.</p><h3>Khi có vấn đề</h3><p>Sử dụng Báo cáo sự cố để phản ánh thông tin sai hoặc lỗi gặp phải. Mô tả cụ thể để đội ngũ quản trị có cơ sở kiểm tra.</p>$article$),
    ('guide', E'1. Chọn Đăng Tin và điền thông tin nhà hoặc phòng.\n2. Gửi tin để Admin duyệt.\n3. Xem trạng thái trong Quản Lý Tin Đăng.\n4. Tìm nhà đã duyệt ở mục Thuê Nhà, Thuê Phòng Trọ, Tìm Ở Ghép hoặc Bản Đồ.', $article$<h2>Bắt đầu theo nhu cầu của bạn</h2><h3>1. Tìm một nơi ở</h3><p>Mở Thuê Nhà, Thuê Phòng Trọ hoặc Tìm Ở Ghép từ trang chủ. Nhập từ khóa, chọn bộ lọc và mở tin để xem thông tin chi tiết.</p><h3>2. Tìm trên bản đồ</h3><p>Mở Bản Đồ để xem vị trí tin. Khi tìm theo bán kính, chọn điểm làm tâm tìm kiếm và khoảng cách phù hợp. Khoảng cách hiển thị là đường chim bay.</p><h3>3. Lưu những tin quan tâm</h3><p>Nhấn trái tim trên tin để lưu vào Yêu thích và mở lại khi cần.</p><h3>4. Đăng và quản lý tin</h3><p>Chọn Đăng Tin, điền loại bất động sản, vị trí, thông tin chi tiết, giá thuê và hình ảnh rồi gửi duyệt. Theo dõi trong Quản Lý Tin Đăng; tin chỉnh sửa sẽ chờ duyệt lại.</p><h3>5. Hợp đồng và gói dịch vụ</h3><p>Mở Quản Lý Hợp Đồng để thao tác với hợp đồng của bạn. Mở Gói Dịch Vụ để xem quyền lợi và lựa chọn gói theo nhu cầu.</p><h3>6. Nhận hỗ trợ</h3><p>Mở Báo Cáo Sự Cố để gửi vấn đề và theo dõi phản hồi. Thông báo trong ứng dụng giúp bạn biết các cập nhật liên quan đến tài khoản.</p>$article$),
    ('contact', 'Thông tin liên hệ hỗ trợ sẽ được cập nhật khi hệ thống chính thức triển khai.', $article$<h2>Bạn cần chúng tôi hỗ trợ?</h2><p>Với lỗi ứng dụng, vấn đề tài khoản, tin đăng, hợp đồng hoặc thanh toán, hãy dùng nút <strong>Gửi và theo dõi báo cáo</strong> bên dưới. Bạn có thể xem tiến độ và phản hồi trong mục Báo cáo sự cố.</p><h3>Thông tin nên chuẩn bị</h3><ul><li>Chức năng và thao tác gặp vấn đề.</li><li>Mã tin, mã hợp đồng hoặc mã giao dịch có liên quan nếu có.</li><li>Thời điểm và nội dung thông báo lỗi.</li></ul><h3>Kênh liên hệ khác</h3><p>Email và số điện thoại hỗ trợ sẽ được công bố tại trang này khi có thông tin chính thức. Không gửi mật khẩu hoặc mã OTP trong nội dung liên hệ.</p>$article$),
    ('support', 'Ghi lại thao tác gặp lỗi và ảnh màn hình, sau đó gửi cho người quản trị theo thông tin ở mục Liên hệ. Chức năng gửi báo cáo trực tiếp trong ứng dụng chưa được kết nối.', $article$<h2>Gửi báo cáo ngay trong ứng dụng</h2><ol><li>Mở Báo cáo sự cố và chọn <strong>Gửi báo cáo mới</strong>.</li><li>Chọn loại sự cố: tài khoản, tin đăng, hợp đồng, thanh toán, lỗi ứng dụng hoặc vấn đề khác.</li><li>Nhập tiêu đề ngắn gọn và mô tả các bước đã thực hiện, kết quả mong đợi, kết quả thực tế và mã liên quan nếu có.</li><li>Nhấn <strong>Gửi báo cáo</strong>. Sau khi được tiếp nhận, bạn có thể mở chi tiết để theo dõi.</li></ol><h3>Theo dõi tiến độ</h3><p>Báo cáo có các trạng thái Mới gửi, Đang xử lý, Đã giải quyết hoặc Từ chối. Phản hồi và các lần cập nhật xuất hiện trong Lịch sử xử lý của từng báo cáo.</p><h3>Nếu gửi thất bại</h3><p>Kiểm tra kết nối và thử gửi lại trên màn hình đang mở. Nội dung đã nhập được giữ lại khi thao tác thất bại.</p>$article$)
)
UPDATE noi_dung_he_thong AS noi_dung
SET noi_dung_ban_nhap = replacement.new_body,
    noi_dung_cong_khai = replacement.new_body,
    thoi_diem_xuat_ban = CURRENT_TIMESTAMP,
    thoi_diem_cap_nhat = CURRENT_TIMESTAMP,
    phien_ban_du_lieu = noi_dung.phien_ban_du_lieu + 1
FROM replacement
WHERE noi_dung.ma_duong_dan_trang = replacement.ma_duong_dan_trang
  AND noi_dung.phien_ban_du_lieu = 0
  AND noi_dung.da_xuat_ban = TRUE
  AND noi_dung.noi_dung_ban_nhap = replacement.old_body
  AND noi_dung.noi_dung_cong_khai = replacement.old_body;

COMMIT;
