# House Rental Management

Ứng dụng quản lý nhà cho thuê: backend Spring Boot theo mô hình Modular Monolith, frontend Flutter cho người dùng và Admin, PostgreSQL/PostGIS.

## Cấu trúc

- `backend/`: ứng dụng Java 21, cấu hình Maven và migration Flyway.
- `frontend/`: ứng dụng Flutter và thư viện giao diện cục bộ `packages/kite_ui`.
- `docs/architecture.md`: quy ước tổ chức mã nguồn và ranh giới module.
- `docs/listing-workflow.md`: hướng dẫn đăng tin, Admin duyệt, bản đồ và quản lý tin.
- `docker-compose.yml`: môi trường cơ sở dữ liệu PostGIS cục bộ.

## Chạy cục bộ

Từ thư mục gốc, chạy `docker compose up -d` để khởi tạo cơ sở dữ liệu. Kiểm tra cấu hình backend trong `backend/src/main/resources/application.yml` và `application.properties` trước khi chạy.

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

`lib/main.dart` giữ cách khởi chạy mặc định trước đây: web mở Admin, các nền tảng khác mở ứng dụng người dùng.

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
