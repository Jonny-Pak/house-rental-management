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
