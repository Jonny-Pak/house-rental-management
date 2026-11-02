# Đăng nhập / đăng ký Google trên app

## Luồng sử dụng

1. Ở trang đăng nhập hoặc đăng ký, bấm nút Google.
2. Chọn tài khoản trong giao diện Google của điện thoại. Hủy sẽ quay lại form, giữ dữ liệu đã nhập.
3. App gửi ID token tới `POST /api/v1/auth/google-login`. Không gửi mật khẩu Google, không dùng email do app tự khai để đăng nhập.
4. Backend xác minh chữ ký, audience (Web Client ID), issuer và hạn token bằng thư viện Google.
5. Tài khoản Google mới được tạo dưới vai trò Member, email đã xác minh và được cấp gói Cơ bản tự động. Không cần OTP email của ứng dụng cho bước này.
6. Tài khoản đã tồn tại được đăng nhập lại, không tạo thêm tài khoản hoặc thêm gói Cơ bản trùng.
7. App chỉ lưu access token do backend cấp, sau đó mở trang chủ và xóa các trang đăng nhập/đăng ký khỏi lịch sử điều hướng.

Tài khoản khóa bị từ chối. Thông tin của tài khoản đã xác minh (họ tên, số điện thoại, mật khẩu, vai trò và gói đang dùng) được giữ lại. Không thể yêu cầu nâng vai trò bằng dữ liệu Google gửi từ app.

Google ID (`sub`) được dùng làm định danh lâu dài. Nếu email Gmail hoặc Google Workspace đã có tài khoản, backend liên kết sau khi Google xác minh quyền sở hữu. Với email bên thứ ba đã có tài khoản, ứng dụng yêu cầu đăng nhập bằng mật khẩu thay vì tự động liên kết chỉ dựa trên email.

Nếu email mới chỉ có bản đăng ký chưa xác minh, backend loại mật khẩu và số điện thoại chưa được xác minh của bản đăng ký cũ trước khi liên kết Google. Chủ email có thể dùng Quên mật khẩu để tạo mật khẩu sau này.

## Tạo cấu hình Google Cloud

Dự án đã cấu hình Web Client ID `163320326790-qpth0te5vfpp3b386lrmbdh1mucqhle8.apps.googleusercontent.com` làm mặc định cho backend và app. Bạn vẫn cần tạo OAuth Android đúng package và SHA-1 trong cùng Google Cloud project trước khi thử chọn tài khoản Google trên điện thoại. Không cần Firebase hoặc client secret cho cách tích hợp này.

1. Mở [Google Cloud Console](https://console.cloud.google.com/), chọn hoặc tạo project.
2. Vào **Google Auth Platform**. Cấu hình **Branding**: tên ứng dụng, email hỗ trợ và email liên hệ.
3. Trong **Audience**, chọn External nếu dùng tài khoản Gmail cá nhân. Nếu ứng dụng đang ở chế độ Testing, thêm email sẽ dùng thử vào Test users.
4. Trong **Clients**, tạo OAuth client loại **Web application**. Sao chép Client ID có đuôi `.apps.googleusercontent.com`. Đây là `GOOGLE_WEB_CLIENT_ID`, dùng giống nhau trên backend và app. Không dùng Android Client ID ở chỗ này. Luồng app gửi ID token tới backend không cần khai báo redirect URI hoặc địa chỉ backend công khai.
5. Trong cùng project, tạo OAuth client loại **Android**:
   - Package name hiện tại: `com.example.frontend`.
   - SHA-1 của debug keystore trên máy hiện tại: `B6:BE:EC:9B:69:58:F8:C4:29:5A:48:FA:78:3B:A9:F3:01:9B:AC:82`.
   - Lưu client. Android Client ID dùng để Google nhận diện package + khóa ký, không cần truyền vào Dart.
6. Khi đổi package hoặc khóa ký (đặc biệt bản phát hành), tạo/cập nhật OAuth Android tương ứng. Không dùng SHA-1 máy khác nếu app không được ký bằng khóa đó.

Có thể tự xem lại SHA-1 trong PowerShell:

```powershell
& 'C:\Program Files\Java\jdk-21.0.12\bin\keytool.exe' -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android
```

## Chạy backend

Backend đã dùng Web Client ID của dự án làm mặc định; có thể chạy bình thường. Khi muốn đổi project Google, đặt biến môi trường trước khi khởi động backend:

```powershell
$env:GOOGLE_WEB_CLIENT_ID = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
.\mvnw.cmd spring-boot:run
```

Nếu bấm Run trong VS Code, tiến trình Java đó cũng phải nhận biến môi trường này, hoặc thêm tham số `--app.google.client-id=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` vào cấu hình chạy Java của bạn.

Nếu chưa cấu hình, server vẫn khởi động được; riêng API Google trả lỗi 503 với thông báo cấu hình, không chấp nhận token mẫu. Không cần migration mới vì bảng users đã có google_id.

## Chạy app Android

Từ thư mục `frontend`:

```powershell
flutter run -d DEVICE_ID --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com --dart-define=API_BASE_URL=http://LAN_IP:8080/api/v1
```

Thay DEVICE_ID, LAN_IP và Web Client ID bằng giá trị thật. Nếu dùng Web Client ID mặc định đã cấu hình trong code, có thể bỏ tham số --dart-define=GOOGLE_WEB_CLIENT_ID. Điện thoại và backend phải kết nối được với nhau; điện thoại cũng cần Internet để đăng nhập Google. Dùng HTTPS cho API khi triển khai ra Internet.

Cần dừng và chạy/cài lại app sau khi thêm plugin hoặc đổi dart-define; Hot Reload không cập nhật các giá trị này. Khi bấm nút, app mở giao diện Google chọn tài khoản; nút bị vô hiệu trong thời gian chờ để tránh gửi nhiều yêu cầu.

Nếu chọn tài khoản rồi bị hủy ngay, kiểm tra đúng package, SHA-1, cùng project và Web Client ID. Google SDK có thể trả trạng thái canceled khi OAuth Android cấu hình sai.

## iOS

Tạo thêm OAuth client loại iOS với Bundle ID của Runner. Truyền `--dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID.apps.googleusercontent.com` cùng GOOGLE_WEB_CLIENT_ID khi chạy.

Trong `frontend/ios/Runner/Info.plist`, thêm một dict vào mảng CFBundleURLTypes đang có (giữ nguyên scheme houserental của thanh toán):

```xml
<dict>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_PREFIX</string>
    </array>
</dict>
```

Dùng REVERSED_CLIENT_ID thật do Google cấp, không giữ nguyên chữ YOUR_IOS_CLIENT_ID_PREFIX. Cấu hình client ID qua Dart nên không cần thêm GIDClientID/GIDServerClientID trong plist. Build và thử iOS cần máy macOS/Xcode; chưa kiểm thử trên máy Windows này.

Google trên Windows và website Admin không được bật trong thay đổi này. Các nền tảng này giữ đăng nhập email/mật khẩu; website Admin có thêm QR. App hiển thị hướng dẫn rõ nếu gọi Google trên nền tảng không hỗ trợ.

## Kiểm thử đã chuẩn bị

- Backend: token có chữ ký RSA thật với khóa kiểm thử; sai chữ ký, audience, issuer và token hết hạn đều bị từ chối. Khóa kiểm thử chỉ nằm trong bộ kiểm thử, không được dùng ở production.
- Tạo Member, cấp gói Cơ bản, đăng nhập lại, liên kết email khác chữ hoa/thường, tài khoản khóa, Google ID xung đột, email chưa xác minh và email bên thứ ba.
- PostGIS trong schema riêng: lưu tài khoản thật, JWT thật và kiểm tra chỉ một subscription sau khi đăng nhập lại. Không dùng tài khoản Google thật trong kiểm thử tự động.
- App: nút Google ở cả hai form, hủy giữ dữ liệu, chờ không cho bấm lặp, lỗi cấu hình, lỗi backend và chỉ lưu token backend khi thành công.

Sau khi cấu hình OAuth thật, thử trên điện thoại: đăng nhập Google mới → hồ sơ/gói Cơ bản → đăng xuất → chọn lại Google đó; kiểm tra vẫn một tài khoản và một gói. Thử hủy chọn tài khoản và tài khoản bị khóa. Người dùng đã xác nhận đăng nhập Google thành công trên thiết bị thật sau khi cấu hình OAuth Android.

Nguồn: [Flutter Google Sign-In](https://pub.dev/packages/google_sign_in), [cấu hình Android](https://pub.dev/packages/google_sign_in_android), [cấu hình iOS](https://pub.dev/packages/google_sign_in_ios), [Google xác minh token và liên kết tài khoản](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token).
