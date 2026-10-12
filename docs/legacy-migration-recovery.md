# Khôi phục lịch sử migration trên database phát triển

Database phát triển đã baseline ở V1 và áp dụng V5, V6, V7. V7 trong database là `V7__create_user_favorites.sql`, nhưng file nguồn không còn trong repository. Migration mới cho quản lý tin đăng trước đó dùng trùng số V7, khiến Flyway không xác thực được lịch sử.

Đã xử lý:

1. Sao lưu database trước khi sửa metadata vào `backend/local-backups/before-legacy-v7-recovery.dump`. Thư mục này được Git bỏ qua vì có thể chứa dữ liệu cá nhân.
2. Dựng lại `V7__create_user_favorites.sql` theo các cột, khóa ngoại, unique constraint và index của bảng hiện có. Đây là bản phục hồi tương đương về schema, không phải nội dung nguyên bản đã mất.
3. Đổi migration quản lý tin thành `V8__listing_management_statuses.sql`.
4. Chạy `backend/scripts/repair-legacy-v7-checksum.sql` một lần trên database cục bộ. Script kiểm tra đúng lịch sử cũ và cấu trúc bảng trước khi đồng bộ riêng checksum V7. Không sửa hàng dữ liệu ứng dụng. Script không chạy tự động và không chạy lại được khi checksum đã sửa.
5. Tắt `clean-on-validation-error` và giữ `clean-disabled=true`, để lỗi migration không dẫn đến tự xóa database.
6. Khi kiểm tra khởi động trên Java 21/Windows, Tomcat NIO gặp lỗi `Unable to establish loopback connection` trong selector của JDK. `WindowsTomcatConfig` chọn protocol NIO2 trên Windows để tránh pipe Unix-domain này. Các hệ điều hành khác giữ protocol mặc định. Có thể tắt tùy chỉnh bằng `rental.server.windows-nio2=false`.

V5 và V6 đã được đối chiếu checksum và giữ nguyên. Database mới chạy các migration V1, V5, V6, V7, V8 từ đầu; database hiện tại tiếp tục từ V7 sang V8.

Không sử dụng Flyway clean, không tắt validation và không xóa lịch sử migration để bỏ qua lỗi. Nếu một database khác gặp vấn đề tương tự, phải kiểm tra và sao lưu riêng trước khi thực hiện recovery.

Đã xác nhận trên database phát triển hiện tại: Flyway validation thành công, V8 áp dụng thành công, Tomcat mở cổng 8080 và `GET /api/v1/listings/public` trả HTTP 200.
