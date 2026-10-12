# Luồng đăng tin và quản lý tin

## Cách sử dụng

1. Khởi động lại backend để Flyway áp dụng migration `V8__listing_management_statuses.sql`. Không sửa migration cũ.
2. Đăng nhập ứng dụng người dùng. Mở tab Danh sách hoặc nút quản lý tin trên bản đồ, chọn Đăng tin.
3. Chọn loại nhà/phòng, vị trí trên bản đồ, địa chỉ, chi tiết, diện tích, giá và mô tả. Chọn tỉnh/thành phố, quận/huyện, phường/xã từ dữ liệu máy chủ và thêm 1–10 ảnh.
4. Bấm Đăng tin. Ứng dụng tải ảnh qua Cloudinary, gửi URL ảnh cùng thông tin tin đăng đến backend. Chỉ báo đã gửi sau khi API lưu tin thành công. Khi lỗi, giữ bản nháp để thử lại.
5. Trong Admin web, đăng nhập bằng tài khoản có role ADMIN, mở Tin đăng. Xem nội dung và ảnh thật của tin chờ duyệt, chọn duyệt hoặc từ chối kèm lý do.
6. Tin có `approvalStatus=APPROVED` và `rentalStatus=AVAILABLE` xuất hiện trên bản đồ. Bản đồ TP.HCM tự tải lại mỗi 30 giây khi ứng dụng hoạt động; có nút tải lại thủ công.
7. Chủ tin mở Quản lý tin đăng để xem trạng thái và lý do từ chối; sửa nội dung/ảnh, ẩn, hiện, đánh dấu đã cho thuê hoặc xóa tin.

Ứng dụng người dùng giữ quy ước hiện có: người đăng nhập có thể đăng tin và trở thành chủ sở hữu của tin đó. Mọi API quản lý lấy user ID từ JWT và kiểm tra owner ID; không nhận owner ID từ client.

## Quy tắc trạng thái

- Tin mới: PENDING + AVAILABLE; chưa công khai.
- Admin duyệt: APPROVED; xuất hiện nếu còn AVAILABLE.
- Admin từ chối: REJECTED; lưu lý do, chưa công khai.
- Sửa nội dung hoặc ảnh: chuyển về PENDING và xóa quyết định duyệt cũ; trạng thái còn trống/ẩn/đã thuê được giữ nguyên.
- Ẩn tin: HIDDEN; vẫn có trong quản lý nhưng không công khai.
- Đã cho thuê: RENTED; không công khai.
- Hiện lại / đánh dấu còn trống: AVAILABLE; chỉ công khai khi đã được duyệt.
- Xóa: DELETED, không công khai và không xuất hiện trong quản lý. Giữ bản ghi để không làm hỏng hợp đồng đã tham chiếu tin.

Các cập nhật cùng một tin sử dụng khóa database để tránh quyết định duyệt ghi đè khi chủ tin đang sửa. Admin chỉ quyết định tin đang PENDING và chưa xóa; quyết định đã xử lý trả 409 để client tải lại.

## API

Các đường dẫn dưới đây có tiền tố `/api/v1`.

| Phương thức | Đường dẫn | Quyền |
|---|---|---|
| POST | `/listings` | Đã đăng nhập |
| GET | `/listings/me` | Đã đăng nhập; chỉ trả tin của caller |
| PUT | `/listings/{id}` | Chủ tin; gửi lại toàn bộ nội dung |
| PATCH | `/listings/{id}/rental-status` | Chủ tin; AVAILABLE, RENTED hoặc HIDDEN |
| DELETE | `/listings/{id}` | Chủ tin; xóa mềm |
| GET | `/listings/public` | Công khai; chỉ APPROVED + AVAILABLE |
| GET | `/listings/map` | Công khai; lọc thêm vùng tọa độ |
| GET | `/admin/listings/pending` | ADMIN |
| PATCH | `/admin/listings/{id}/approve` | ADMIN |
| PATCH | `/admin/listings/{id}/reject` | ADMIN; lý do tối đa 255 ký tự |

Tài khoản Admin phải được cấp trước; API đăng ký công khai không chấp nhận role ADMIN. Session Admin được khôi phục qua `/users/me`, không suy đoán quyền từ việc có token.

## Kiểm thử

- Backend: `mvn test` chạy các test trạng thái, quyền truy cập HTTP, quyền sở hữu và gửi duyệt lại. Test PostGIS được bỏ qua mặc định.
- Frontend: `flutter test --no-pub` kiểm tra gửi tin, lỗi upload/API, chống gửi trùng, thiếu khu vực, trạng thái và lý do từ chối trong quản lý.
- Analyzer: `dart analyze lib test`.
- Kiểm thử database thật: đặt `RENTAL_POSTGIS_TESTS=true`, chạy `mvn -Dtest=ListingPostgisTest test`. Test sử dụng database trong `application.yml`, tạo schema riêng có tên ngẫu nhiên, chạy Flyway/JPA và xóa schema sau test. Chỉ chạy với database phát triển cục bộ.

Cloudinary cần cấu hình hợp lệ để tải ảnh thật. Dữ liệu khu vực hiện có chỉ là dữ liệu seed; lựa chọn phường/xã phụ thuộc dữ liệu đã có trong database.
