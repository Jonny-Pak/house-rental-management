# Tin tìm người ở ghép

- Chọn **Đăng Tin → Tìm người ở ghép**. Điền vị trí, số người đang ở, sức chứa, giới tính ưu tiên, quy định sinh hoạt, ảnh và chi phí.
- Giá thuê và tiền cọc của tin `SHARED_ROOM` là chi phí cho mỗi người. Điện/nước và cách chia chi phí ghi trong yêu cầu hoặc mô tả.
- Sức chứa tối đa 20 người và phải lớn hơn số người đang ở. Số chỗ cần tìm được tính bằng sức chứa trừ số người đang ở.
- Tin mới ở trạng thái `PENDING`. Admin xem thông tin ở ghép và duyệt hoặc từ chối như các loại tin khác.
- Tin đã duyệt, còn trống xuất hiện trong **Tìm Ở Ghép**, tìm kiếm chung và bản đồ. Bộ lọc hỗ trợ loại tin, giá mỗi người và giới tính. Lọc Nam/Nữ vẫn bao gồm tin không yêu cầu giới tính.
- Người đăng chỉnh sửa thông tin ở ghép tại Quản lý tin đăng; chỉnh sửa gửi duyệt lại. Ẩn, đánh dấu đã thuê và xóa dùng luồng hiện có.
- Khởi động lại backend để Flyway áp dụng `V14__shared_room_details.sql`. Migration thêm trường và kiểm tra số người, không xóa dữ liệu tin đăng.

## Kiểm thử

- Flutter: `flutter test test/shared_room_test.dart test/listing_flow_test.dart test/rental_filter_test.dart`
- Backend API: `mvn -Dtest=ListingSecurityTest test`
- PostGIS: đặt `RENTAL_POSTGIS_TESTS=true`, chạy `mvn -Dtest=ListingPostgisTest test`. Kiểm thử dùng schema riêng và tự dọn sau khi chạy.
