# Quên mật khẩu và đổi mật khẩu

## Quên mật khẩu

App: chọn **Quên mật khẩu?** ở trang đăng nhập. Website Admin: chọn **Forgot password?**.

1. Nhập email tài khoản đã xác thực và đang hoạt động.
2. Gửi mã OTP, kiểm tra hộp thư và Spam. Gửi lại sau 60 giây.
3. Nhập mã 6 chữ số, mật khẩu mới và nhập lại mật khẩu mới.
4. Sau khi thành công, quay lại đăng nhập bằng mật khẩu mới.

Mã hiệu lực 5 phút, dùng một lần, tối đa 5 lần nhập sai. Mã xác thực đăng ký không dùng để đặt lại mật khẩu. Gửi mã mới làm mã đặt lại trước đó hết hiệu lực. Thông báo yêu cầu gửi mã không tiết lộ email có tồn tại hay không; tài khoản khóa/chưa xác thực không được gửi mã.

OTP dùng bộ nhớ backend như luồng xác thực đăng ký hiện tại. Nếu khởi động lại backend, yêu cầu mã mới. Backend nhiều instance cần kho OTP dùng chung trước khi triển khai theo mô hình đó.

## Đổi mật khẩu

Member: **Tài khoản → Đổi mật khẩu**. Admin: **Profile → Đổi mật khẩu**.

Nhập mật khẩu hiện tại, mật khẩu mới và xác nhận. Mật khẩu mới tối thiểu 8 ký tự, tối đa 72 byte UTF-8 (giới hạn BCrypt), không trùng mật khẩu hiện tại. Không cắt khoảng trắng trong mật khẩu. Tài khoản chỉ đăng nhập Google có thể dùng quên mật khẩu qua email để tạo mật khẩu lần đầu.

Khi đổi thành công, đăng xuất và đăng nhập lại. Backend tăng password_version, vô hiệu hóa cả token access và refresh đã cấp trước đó. OTP đặt lại đang chờ cũng hết hiệu lực. Các tài khoản khác không bị ảnh hưởng.

## API

- POST /api/v1/auth/forgot-password: email.
- POST /api/v1/auth/reset-password: email, otp, newPassword.
- POST /api/v1/users/me/change-password: currentPassword, newPassword; yêu cầu đăng nhập, chỉ đổi mật khẩu của người gọi.

Mật khẩu lưu bằng BCrypt; không trả mật khẩu/OTP trong API hoặc ghi vào log. Email dùng cùng cấu hình SMTP hiện có, nội dung và tiêu đề riêng cho đặt lại mật khẩu. Lỗi gửi email hiển thị lỗi, xóa mã gửi thất bại để có thể thử lại.

## Áp dụng

Khởi động lại backend để Flyway chạy **V20__password_version.sql**, rồi chạy lại app/website. Không sửa migration cũ. Token cũ không có passwordVersion vẫn dùng được khi tài khoản chưa từng đổi mật khẩu; sau khi đổi sẽ bị từ chối.

Kiểm thử tự động dùng mail giả để không gửi email thật. Kiểm thử PostGIS dùng schema riêng. Để kiểm tra gửi email thực tế, dùng email của bạn trên môi trường đã cấu hình SMTP, nhận OTP và đăng nhập lại sau đặt mật khẩu mới.
