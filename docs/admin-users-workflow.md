# Admin quản lý người dùng

Website Admin có mục **Quản lý người dùng** trong menu Quản lý.

## Thao tác

- Xem danh sách, tìm theo họ tên/email/số điện thoại; lọc vai trò, trạng thái và xác thực email.
- Phân trang 20 tài khoản; xem thông tin chi tiết và thời gian tạo/cập nhật.
- Sửa họ tên và số điện thoại của Member. Có thể để trống số điện thoại.
- Khóa/mở khóa tài khoản sau khi xác nhận. Người dùng nhận thông báo hệ thống khi thay đổi thông tin/trạng thái.
- Tài khoản Admin chỉ được xem ở trang này; không tự khóa tài khoản hoặc cấp quyền Admin.
- Email, mật khẩu và trạng thái xác thực không sửa qua trang quản lý. Không xóa dữ liệu người dùng có liên quan đến hợp đồng/tin đăng.

## Thêm người dùng

Nhấn **Thêm người dùng**, nhập họ tên, email, số điện thoại (không bắt buộc), mật khẩu ban đầu/nhập lại. Tài khoản có vai trò Member. Chọn **Tạo và gửi OTP**.

- Email được chuẩn hóa thành chữ thường; không cho phép email hoặc số điện thoại trùng.
- Mật khẩu tối thiểu 8 ký tự, tối đa 72 byte UTF-8, lưu bằng BCrypt; không gửi mật khẩu trong email hoặc trả về API.
- Tài khoản mới chưa xác thực email. Email OTP có hiệu lực 5 phút.
- Gửi email thất bại sẽ rollback tài khoản mới và hủy OTP, để có thể thử lại.
- Trên app: nhập email tại trang Đăng nhập → **Xác thực email** → nhập OTP hoặc gửi lại mã → đăng nhập bằng mật khẩu ban đầu.
- Tạo thành công sẽ xóa bộ lọc và tải lại trang đầu để hiển thị tài khoản mới. Các thông tin Admin đăng nhập vẫn giữ nguyên.
- Chưa gửi email thật trong kiểm thử tự động: dùng bộ gửi email giả, có kiểm tra rollback trên cơ sở dữ liệu thật.

## API

Các API yêu cầu tài khoản Admin đang hoạt động, đã xác thực:

| Phương thức | Đường dẫn | Chức năng |
| --- | --- | --- |
| POST | `/api/v1/admin/users` | `fullName`, `email`, `phoneNumber`, `password`, `role`; trả 201 khi tạo và gửi OTP thành công |
| GET | `/api/v1/admin/users` | `query`, `role`, `status`, `verified`, `page` (từ 0) |
| GET | `/api/v1/admin/users/{id}` | Thông tin chi tiết |
| PUT | `/api/v1/admin/users/{id}` | `fullName`, `phoneNumber`, `role` (`MEMBER`) |
| PATCH | `/api/v1/admin/users/{id}/status` | `status` (`ACTIVE`/`LOCKED`) |

API trả về thông tin hiển thị, không trả password hash, Google ID hoặc token.
Số điện thoại trùng trả 409; dữ liệu sai trả 400; không có tài khoản trả 404; truy cập trái quyền trả 403.
Trạng thái khóa được kiểm tra khi đăng nhập bằng mật khẩu/Google và trên mỗi yêu cầu có JWT, kể cả token đã phát trước khi khóa.
Mở khóa không tự xác thực email. Token chưa hết hạn có thể dùng lại sau khi mở khóa nếu tài khoản đã xác thực.

## Kiểm tra thủ công

1. Khởi động lại backend và website Admin sau khi cập nhật code. Mở app bằng một tài khoản người dùng đã xác thực.
2. Admin tìm tài khoản bằng email hoặc số điện thoại; thử kết hợp bộ lọc và chuyển trang.
3. Xem chi tiết, sửa tên/số điện thoại rồi lưu. Thử tên trống và số điện thoại trùng để kiểm tra thông báo lỗi.
4. Nhấn Khóa, thử Hủy trước, sau đó xác nhận. Dùng app tải lại hồ sơ hoặc danh sách riêng: yêu cầu phải bị chặn; đăng nhập lại cũng bị chặn.
5. Admin mở khóa; tài khoản đã xác thực được đăng nhập lại và thấy thông báo hệ thống.
6. Kiểm tra tài khoản chưa xác thực vẫn phải xác thực email sau khi mở khóa. Hàng Admin không có thao tác sửa/khóa.
7. Thử màn hình trình duyệt hẹp: danh sách chuyển thành thẻ và hộp thoại cuộn được.

Migration V17 chuyển tài khoản USER/OWNER cũ thành MEMBER, giữ nguyên ID, tin đăng, hợp đồng và dữ liệu liên quan. Hệ thống chỉ có hai vai trò MEMBER và ADMIN. Member vừa thuê nhà vừa đăng và quản lý tin cho thuê; quyền trên từng hợp đồng/tin đăng vẫn kiểm tra theo người tham gia/chủ sở hữu. Không chỉnh sửa migration cũ.
