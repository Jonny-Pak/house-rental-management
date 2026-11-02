# Đăng nhập website Admin bằng QR

## Cách sử dụng

1. Website Admin → **Đăng nhập bằng QR**. Website hiển thị mã QR và mã đối chiếu 6 số, có hiệu lực 2 phút.
2. Trên app, đăng nhập bằng tài khoản có vai trò **Admin**.
3. Mở **Cá nhân** hoặc menu bên → **Quét QR đăng nhập Admin**. Tài khoản Member không thấy mục này.
4. Cấp quyền camera và quét QR trên màn hình máy tính. Nếu thiết bị không có camera, bấm biểu tượng sao chép cạnh mã đối chiếu trên website rồi dán vào mục nhập nội dung QR trên app.
5. App hiển thị địa chỉ website, trình duyệt, mã đối chiếu và giờ hết hạn. So sánh với máy tính, chỉ bấm **Xác nhận đăng nhập** nếu chính bạn đang mở website đó. Có thể bấm **Từ chối**.
6. Website kiểm tra trạng thái mỗi 2 giây. Khi được xác nhận, website đổi phiên QR lấy token riêng, kiểm tra lại tài khoản Admin rồi mở trang quản trị.

Quét QR chưa làm website đăng nhập. App không gửi token hiện tại của điện thoại vào QR và không thay đổi phiên đăng nhập trên app.

## Cấu hình môi trường local

Website và app phải gọi cùng backend và cùng cơ sở dữ liệu. Không cần URL công khai để thử QR trong cùng mạng LAN.

Backend mặc định chấp nhận website `http://localhost:8081`. Nếu website mở bằng địa chỉ khác, đặt biến môi trường trước khi khởi động backend:

```powershell
$env:ADMIN_WEB_ORIGIN = 'http://localhost:8081'
```

Chạy website từ thư mục `frontend`:

```powershell
flutter run -d chrome --web-port 8081
```

Chạy app trên điện thoại trỏ về IP LAN của máy chạy backend:

```powershell
flutter run -d DEVICE_ID --dart-define=API_BASE_URL=http://LAN_IP:8080/api/v1
```

Thay `DEVICE_ID` và `LAN_IP` bằng giá trị thực tế. Ví dụ nếu website mở bằng `http://192.168.1.10:8081`, biến `ADMIN_WEB_ORIGIN` cũng phải là địa chỉ đó. Chỉ cấu hình origin gồm giao thức, host và cổng; không thêm đường dẫn.

Khi triển khai qua Internet, dùng HTTPS cho cả website và backend và đặt `ADMIN_WEB_ORIGIN` khớp website Admin. Cấu hình origin chỉ giúp xác định website yêu cầu đăng nhập; người dùng vẫn phải tự kiểm tra máy tính và mã đối chiếu, không xác nhận QR do người khác gửi.

Cần **khởi động lại backend** để áp dụng migration V27 và cấu hình origin. Cần cài/chạy lại app sau khi thêm plugin camera và quyền camera; Hot Reload không đủ. Android và iOS đã khai báo quyền camera. Windows có cách nhập nội dung QR khi không dùng camera.

## Cách xử lý trong code

- `QrLoginService.start`: server tạo ID phiên, hai khóa ngẫu nhiên riêng biệt và mã đối chiếu. Chỉ lưu hash của hai khóa trong database.
- QR chứa ID và khóa quét. Khóa của trình duyệt chỉ nằm trong bộ nhớ trang đăng nhập, không nằm trong QR.
- `preview`: kiểm tra tài khoản Admin, khóa quét và hạn dùng. Gắn phiên vào Admin đã quét và chuyển sang `SCANNED`; chưa cấp token.
- `decide`: chỉ Admin đã quét mới được xác nhận/từ chối. Xác nhận chuyển sang `APPROVED`; từ chối chuyển sang `REJECTED`.
- `consume`: chỉ trình duyệt giữ đúng khóa mới đổi được phiên. Kiểm tra lại Admin đang hoạt động, đã xác thực, chưa đổi mật khẩu và QR còn hạn. Khóa dòng dữ liệu khi đổi phiên; chuyển sang `CONSUMED` sau khi tạo token.
- Website chỉ lưu token sau khi API hồ sơ xác nhận đúng tài khoản Admin. Các request chứa khóa hoặc token đều trả `Cache-Control: no-store`.
- Chuyển về đăng nhập email/mật khẩu hoặc tạo QR mới sẽ hủy phiên cũ. Tải lại trang làm mất khóa đang giữ trong bộ nhớ; cần tạo QR mới.
- Giới hạn tạo 20 phiên mỗi phút trên một địa chỉ kết nối. Phiên QR đã hết hạn hơn một giờ được dọn khi tạo phiên mới. Không xóa người dùng hoặc dữ liệu nghiệp vụ.

Các hàm được tách theo từng bước; dùng `if/else`, trạng thái dạng chuỗi, giao dịch và khóa dòng của Spring/JPA. Không dùng WebSocket hay hệ thống hàng đợi.

## API

- `POST /api/v1/auth/qr/start`: tạo phiên từ origin website Admin đã cấu hình.
- `POST /api/v1/auth/qr/{id}/status`: trạng thái, cần `browserSecret`; không trả token.
- `POST /api/v1/auth/qr/{id}/consume`: đổi phiên đã được duyệt, cần `browserSecret`; chỉ dùng được một lần.
- `POST /api/v1/auth/qr/{id}/cancel`: hủy phiên, cần `browserSecret`.
- `POST /api/v1/admin/qr-login/{id}/preview`: bắt buộc quyền Admin, cần `scanToken`.
- `POST /api/v1/admin/qr-login/{id}/decision`: bắt buộc quyền Admin, cần `scanToken` và `approve`.

`browserSecret` và `scanToken` được gửi trong JSON, không gửi trên query string của các API. QR có `scanToken` vì đây là dữ liệu cần truyền từ màn hình máy tính sang camera; token đăng nhập không được đưa vào QR.

## Kiểm thử

Backend: toàn bộ vòng đời, mã sai/hết hạn, Member bị từ chối, tài khoản khóa/chưa xác thực, đổi quyền/đổi mật khẩu sau khi xác nhận, hủy và từ chối, dùng sai loại khóa, giới hạn tạo mã, hai yêu cầu đổi phiên đồng thời. Migration và cấp JWT được kiểm tra trên PostGIS trong schema riêng.

Frontend: website chờ xác nhận, đổi token một lần, hết hạn/từ chối/thử lại, hủy khi rời trang, xác nhận trên app, không xác nhận ngay khi quét, QR sai không gọi API, chỉ Admin thấy nút, giữ chức năng đăng nhập mật khẩu, màn hình nhỏ và chữ lớn. Kiểm thử camera trên thiết bị thật cần thực hiện sau khi cài app và cấp quyền camera.

Thư viện: [barcode](https://pub.dev/packages/barcode) tạo QR dạng SVG; [mobile_scanner](https://pub.dev/packages/mobile_scanner) nhận QR từ camera.
