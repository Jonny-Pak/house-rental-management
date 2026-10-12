# Quy ước cấu trúc mã nguồn

## Backend

```text
backend/src/main/java/com/rental/
├── HouseRentalManagementApplication.java
├── core/
│   ├── dto/             # Kiểu phản hồi API dùng chung
│   ├── exception/       # Xử lý lỗi chung
│   └── security/        # JWT và Spring Security
└── modules/<module>/
    ├── controller/      # Endpoint HTTP
    ├── dto/             # Request/response của module
    ├── domain/entity/   # Entity nghiệp vụ
    ├── repository/      # Truy cập dữ liệu
    └── service/         # Xử lý nghiệp vụ
```

Chỉ tạo thư mục khi có mã nguồn tương ứng. Module có thể bổ sung `config`, `domain/enums` hoặc `specification` khi cần. Migration nằm trong `src/main/resources/db/migration`; kiểm thử Java đặt trong `src/test/java/com/rental`, phản chiếu package mã nguồn.

`core` chứa thành phần được nhiều module sử dụng. Cấu hình riêng của Cloudinary và VNPAY vẫn thuộc module `media` và `payment`.

Backend hiện dùng một ứng dụng và một cơ sở dữ liệu. Một số service vẫn truy cập repository/entity của module khác; việc tổ chức thư mục chưa tạo ra ranh giới module được cưỡng chế. Khi mở rộng, ưu tiên cung cấp service/facade của module sở hữu nghiệp vụ và giảm truy cập repository xuyên module. Quan hệ JPA giữa entity các module đang được giữ nguyên.

## Frontend

```text
frontend/lib/
├── main.dart            # Entry point mặc định, giữ tương thích
├── main_user.dart       # Entry point ứng dụng người dùng
├── main_admin.dart      # Entry point Admin web
├── app/
│   ├── user/            # Widget ứng dụng người dùng
│   └── admin/           # Khởi tạo, session, router, theme, l10n
├── core/                # API client và token storage dùng chung
├── shared/admin/        # Layout và widget dùng chung của Admin
├── features/<feature>/
│   ├── data/            # Model, repository, datasource/provider
│   └── presentation/    # Page, screen, widget, Bloc/Cubit
└── demo/                # Màn hình mẫu và phiên bản giao diện cũ
```

Model đặt ở feature sở hữu dữ liệu: `Listing` thuộc `listing`, không thuộc `home`. Luồng tải tin công khai đi từ page qua Cubit, `ListingRepository`, rồi `ApiClient`.

Admin dùng Riverpod cho shell, session và màn hình mẫu; các tính năng nghiệp vụ dùng Bloc/Cubit hiện có. Hai cách quản lý trạng thái được giữ nguyên trong lần tổ chức lại này.

`demo/admin` chứa các ví dụ apps, components, forms, resources và project dashboard. Command palette hiện vẫn sử dụng schema/provider của phần mẫu. Dashboard Admin hiện vẫn dùng `MockDataProvider`, đặt trong `features/admin/data/providers`; tách thư mục không có nghĩa các màn hình đã nối API thật.

`frontend/packages/kite_ui` là thư viện giao diện dùng chung, có cấu trúc và ứng dụng ví dụ riêng. Không di chuyển thư viện này vào `lib/features`.

## Phạm vi thay đổi

Chuẩn hóa entity, chuyển `ApiResponse` về `core`, tách cấu hình ứng dụng Admin khỏi feature, tách demo, chuyển model tin đăng về nơi sở hữu và bổ sung repository tải tin công khai. Không thay đổi schema cơ sở dữ liệu hoặc API nghiệp vụ. Controller thử thanh toán được giới hạn bằng profile `dev`.

AI Agent, tài liệu UML/ERD, kiểm thử nghiệp vụ và cấu hình triển khai toàn hệ thống cần bổ sung khi các phần đó được thực hiện; không tạo thư mục rỗng để biểu thị chức năng đã có.
