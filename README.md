# House Rental Management

Ứng dụng quản lý nhà cho thuê: backend Spring Boot theo mô hình Modular Monolith, frontend Flutter cho người dùng và Admin, PostgreSQL/PostGIS.

## Cấu trúc

- `backend/`: ứng dụng Java 21, cấu hình Maven và file khởi tạo `database.sql`.
- `frontend/`: ứng dụng Flutter và thư viện giao diện cục bộ `packages/kite_ui`.
- `docs/architecture.md`: quy ước tổ chức mã nguồn và ranh giới module.
- `docs/nearby-search-workflow.md`: tìm nhà quanh vị trí theo bán kính và khoảng cách.
- `docs/listing-workflow.md`: hướng dẫn đăng tin, Admin duyệt, bản đồ và quản lý tin.
- `docs/incidents-workflow.md`: người dùng gửi báo cáo sự cố, Admin xử lý và phản hồi.
- `docs/admin-contracts-workflow.md`: Admin tra cứu toàn bộ hợp đồng và xem chi tiết.
- `docs/admin-packages-workflow.md`: Admin quản lý gói và bảo toàn thông tin gói đã mua.
- `docs/admin-amenities-workflow.md`: Admin quản lý nội thất/tiện ích, kết nối với tin đăng và Excel.
- `docs/subscription-benefits-workflow.md`: áp dụng lượt đăng tin, nâng VIP và làm mới theo gói dịch vụ.
- `docs/vnpay-app-workflow.md`: thanh toán VNPAY, IPN, quay lại app và lịch sử giao dịch.
- `docs/admin-qr-login-workflow.md`: đăng nhập website Admin bằng QR, xác nhận qua app.
- `docs/ckeditor-content.md`: soạn thảo nội dung định dạng bằng CKEditor và cấu hình giấy phép.
- `docker-compose.yml`: môi trường cơ sở dữ liệu PostGIS cục bộ.

## Chạy cục bộ

Từ thư mục gốc, chạy `docker compose up -d` để khởi tạo cơ sở dữ liệu. Kiểm tra cấu hình backend trong `backend/src/main/resources/application.yml` và `application.properties` trước khi chạy.

Với database mới, import `backend/database.sql` một lần trước khi chạy backend. Phiên bản này dùng 23 bảng tiếng Việt không dấu. Database hiện có cần sao lưu rồi chạy script đổi tên (nếu còn tên tiếng Anh) và script rút gọn theo [backend/README.md](backend/README.md); không import lại file khởi tạo lên dữ liệu hiện có.

Backend:

```powershell
cd backend
mvn spring-boot:run
```

Frontend:

```powershell
cd frontend
flutter pub get
flutter run -t lib/main_user.dart
flutter run -d chrome -t lib/main_admin.dart
```

`lib/main.dart` tự phân chia theo nền tảng: website chỉ mở Admin, Android/iOS và Windows chỉ mở ứng dụng người dùng. Không còn màn hình chọn giao diện hoặc chuyển sang Admin trên app. Các entry point `main_user.dart` và `main_admin.dart` cũng tuân theo quy tắc này.

Endpoint `/api/v1/auth/test-payment` chỉ được đăng ký khi backend chạy với profile `dev`.

## Kiểm tra

```powershell
cd backend
mvn test
```

```powershell
cd frontend
flutter analyze
flutter test
```

Các chức năng chưa hoàn thành được đánh giá riêng với cấu trúc mã nguồn; xem tài liệu kiến trúc để biết các giới hạn còn lại.

- [Đăng nhập / đăng ký Google và cấu hình OAuth](docs/google-login-workflow.md)

- [Chatbot tìm nhà chạy nội bộ và hướng dẫn huấn luyện](docs/chatbot-workflow.md)
