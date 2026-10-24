# Giao diện Flutter

Website chỉ chạy giao diện Admin. App Android/iOS và Windows chạy giao diện người dùng, không có màn hình chọn hoặc chuyển sang Admin.

Chạy từ thư mục `frontend`, mỗi giao diện dùng một terminal:

```powershell
# App người dùng (chọn điện thoại hoặc thiết bị Android/iOS)
flutter run

# Website Admin
flutter run -d chrome --web-port 8081

# Ứng dụng người dùng trên Windows
flutter run -d windows
```

Các entry point cũ `main_user.dart` và `main_admin.dart` cùng dùng cách phân chia theo nền tảng này. Backend vẫn kiểm tra quyền Admin khi đăng nhập website.

## Bố cục thích ứng

Các giá trị dưới đây là logical pixel, dựa trên kích thước cửa sổ thực:

| Phần giao diện | Màn hình nhỏ | Màn hình vừa/lớn |
| --- | --- | --- |
| Người dùng | Dưới 600: điều hướng dưới | Từ 600: NavigationRail; từ 1024: nhãn bên cạnh icon |
| Admin | Dưới 1024: drawer và điều hướng dưới | Từ 1024: sidebar |
| Danh sách tin/hợp đồng | Một cột | Tự chia 2–3 cột theo chiều rộng vùng nội dung |
| Duyệt tin Admin | Card, nút xuống dòng | Bảng khi vùng nội dung đạt 900 |
| Bộ lọc tin | Bottom sheet | Dialog từ chiều rộng cửa sổ 600 |
| Biểu mẫu | Theo chiều rộng khả dụng | Tối đa 760; nhóm ngày/tiền hợp đồng chia hai cột khi đủ chỗ |

`lib/core/layout/app_layout.dart` chứa giới hạn kích thước, khung nội dung, bố cục card và cuộn bằng chuột/touchpad. Tab và luồng đang mở được giữ khi resize. Bản đồ sử dụng toàn bộ vùng nội dung khả dụng.

Đăng nhập/đăng ký hỗ trợ chuyển trường bằng bàn phím và gửi bằng Enter ở ô mật khẩu. Home hỗ trợ tăng cỡ chữ hệ thống.

## Kiểm tra

```powershell
flutter analyze lib test
flutter test
flutter build web
flutter build windows
```

`test/responsive_ui_test.dart` và `test/admin_responsive_test.dart` kiểm tra màn hình 320–1440, Android/Windows, trạng thái khi resize, chữ lớn và hộp thoại Admin.

Windows cần Visual Studio có workload Desktop development with C++ và MSVC đầy đủ. Nếu báo compiler `14.52.36615` không tồn tại trong khi bản `14.51.36231` có sẵn, cần sửa cài đặt MSVC trong Visual Studio Installer. Lỗi này cũng ảnh hưởng việc build native assets của widget tests trên máy đó.
