# Địa chỉ TP.HCM sau sáp nhập năm 2025

Phạm vi hiện tại của dự án là TP.HCM mới, bao gồm địa bàn TP.HCM,
Bình Dương và Bà Rịa–Vũng Tàu trước sáp nhập.

Migration `V10__hcm_post_merger_commune_level_areas.sql` bổ sung 168 đơn vị
cấp xã: 113 phường, 54 xã và đặc khu Côn Đảo. Các đơn vị mới có `parent_id`
trực tiếp trỏ đến bản ghi thành phố (`code = SG`), dùng mô hình địa chỉ hai cấp.
Không xóa hoặc gán lại ID các quận/huyện và phường cũ vì tin đăng, khu trọ
đã lưu có thể đang tham chiếu chúng. Không tự chuyển địa chỉ cũ sang tên mới:
một số đơn vị cũ được chia sang nhiều đơn vị mới.

Nguồn danh sách là [Báo Chính phủ, danh sách 168 đơn vị TP.HCM](https://xaydungchinhsach.chinhphu.vn/sap-xep-dvhc-danh-sach-168-xa-phuong-dac-khu-cua-thanh-pho-ho-chi-minh-119250623085031865.htm),
theo Nghị quyết 1685/NQ-UBTVQH15 ngày 16/06/2025.
Dữ liệu tên được lưu UTF-8, chuẩn Unicode NFC; bản đối chiếu nằm trong
`hcm-areas-2025.json`. Mã `HCM25-001`…`HCM25-168` là định danh nội bộ ổn định
của ứng dụng, không phải mã đơn vị hành chính do Nhà nước ban hành.
Đề án chuyển 29 xã thành phường được HĐND thông qua tháng 8/2026 chưa được
đưa vào bộ dữ liệu này vì nguồn đang mô tả bước xây dựng đề án, không cung cấp
nghị quyết thành lập có hiệu lực:
[Báo Chính phủ, đề án 29 phường](https://tphcm.baochinhphu.vn/hdnd-tphcm-thong-qua-viec-lap-them-29-phuong-101260827143610802.htm).

API công khai mới: `GET /api/v1/areas/provinces/{provinceId}/wards`.
Mỗi mục có `id`, `name`, `code`, `provinceId`, `type` (`WARD`, `COMMUNE`,
`SPECIAL`), `districtId = null`. Các API quận/huyện cũ được giữ để đọc dữ liệu
lịch sử. Khi tạo khu trọ theo địa chỉ hai cấp, bỏ trường `districtId`.
Backend kiểm tra phường/xã thuộc đúng tỉnh/thành phố trước khi lưu khu trọ.

Các bộ chọn địa chỉ đăng tin, tạo khu trọ, sở thích tìm thuê và bộ lọc khu trọ
dùng API mới. Màn hình đăng tin có tìm kiếm địa danh không dấu và nút tải lại
khu vực. Sau cập nhật mã, khởi động lại backend và Hot Restart Flutter.
Flyway tự áp dụng migration; không cần chạy SQL thủ công hoặc sửa checksum.

Kiểm thử PostGIS chạy trên schema riêng: đủ số lượng/tên/loại/quan hệ cha,
áp dụng lại SQL không thêm trùng, giữ ID phường cũ, đăng tin và tạo khu trọ
với cả ba loại đơn vị mới. Kiểm thử Flutter kiểm tra JSON hai cấp,
tìm không dấu, giữ lựa chọn khi tải lại và phục hồi sau lỗi API.
