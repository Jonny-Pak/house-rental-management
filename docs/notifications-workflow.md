# Thông báo hệ thống

## Người dùng

- Mở chuông trên trang chủ hoặc tab **Thông báo**.
- Xem tất cả / chỉ chưa đọc; kéo xuống làm mới; tải thêm từng trang 25 thông báo.
- Chạm thông báo để xem đầy đủ nội dung và đánh dấu đã đọc. Chọn **Xem tin đăng / Xem hợp đồng** trong hộp thoại nếu muốn mở mục liên quan.
- Nút ba chấm ở từng thông báo cho phép **Đánh dấu đã đọc / Đánh dấu chưa đọc** hoặc **Xóa thông báo**. Xóa luôn có bước xác nhận.
- Nút **Quản lý thông báo** trên thanh tiêu đề cho phép xóa các thông báo đã đọc. Thông báo chưa đọc được giữ lại; tin đăng và hợp đồng không bị ảnh hưởng.
- **Đọc tất cả** chỉ tác động đến tài khoản hiện tại.
- Số chưa đọc hiển thị ở chuông trang chủ, thanh điều hướng và nút chuông Admin. Không hiển thị số 0, số lớn hơn 99 hiển thị `99+`.

Ứng dụng kiểm tra cập nhật mỗi 30 giây khi đang mở, làm mới khi quay lại ứng dụng hoặc vào trang thông báo. Tạm dừng kiểm tra nền khi ứng dụng không hoạt động và hủy khi đăng xuất/rời màn hình chính.

## Thông báo theo nghiệp vụ

| Sự kiện | Người nhận |
| --- | --- |
| Gửi tin / sửa tin cần duyệt lại | Chủ tin và Admin đang hoạt động |
| Admin duyệt / từ chối tin | Chủ tin; từ chối kèm lý do |
| Tạo hợp đồng chờ xác nhận | Người thuê |
| Chủ nhà sửa hợp đồng | Người thuê mới; người thuê cũ nhận thông báo nếu được thay thế |
| Xác nhận / hủy / kết thúc hợp đồng | Bên còn lại của hợp đồng |
| Hợp đồng chuyển sang hết hạn qua luồng kiểm tra trạng thái hiện có | Cả hai bên, không tạo thêm khi đọc lại |
| Admin gửi thông báo chung | Tài khoản đang hoạt động và đã xác thực |

Thông báo nghiệp vụ lưu cùng giao dịch với tin/hợp đồng, bao gồm dữ liệu được nhập Excel. Nếu nghiệp vụ hoàn tác thì thông báo cũng được hoàn tác. Không tạo thông báo từ thao tác xem trước Excel/hợp đồng.

## Admin

Mở chuông trên thanh công cụ Admin, chọn **Gửi thông báo chung**. Nhập tiêu đề tối đa 150 ký tự và nội dung tối đa 500 ký tự; xem lại nội dung trong hộp xác nhận rồi gửi. Màn hình báo số tài khoản nhận thành công. Hủy hộp xác nhận sẽ không gửi.

Thông báo tin đang chờ duyệt mở trang kiểm duyệt. Thông báo tin của người dùng mở quản lý tin; thông báo hợp đồng mở chi tiết hợp đồng và vẫn kiểm tra quyền truy cập tại backend.

## API

- `GET /api/v1/notifications?page=0&unreadOnly=false`
- `GET /api/v1/notifications/unread-count`
- `PATCH /api/v1/notifications/{id}/read`
- `PATCH /api/v1/notifications/read-all`
- `PATCH /api/v1/notifications/{id}/unread`
- `DELETE /api/v1/notifications/{id}`
- `DELETE /api/v1/notifications/read` (chỉ các thông báo đã đọc của tài khoản hiện tại)
- `POST /api/v1/admin/notifications/broadcast` với JSON `title`, `content` (chỉ Admin).

Danh tính lấy từ phiên đăng nhập, không nhận `userId` từ phía người dùng. Đánh dấu thông báo của tài khoản khác trả 404. Đánh dấu đã đọc nhiều lần không tăng hoặc giảm sai số chưa đọc.

Sau khi máy chủ xác nhận thao tác, giao diện cập nhật trạng thái ngay. Nếu bước tải lại danh sách sau đó lỗi mạng, trạng thái vừa lưu vẫn được giữ và có thể thử tải lại. Đổi bộ lọc không hiển thị nhầm dữ liệu cũ khi mất mạng.

## Phạm vi và kiểm thử

Đây là thông báo lưu trong ứng dụng; chưa bao gồm push lên thanh thông báo Android/iOS, email hoặc SMS. Không cần dịch vụ bên ngoài hay khóa Firebase.

Migration **V16** bổ sung chỉ mục và chuẩn hóa trạng thái đã đọc trên bảng `notifications` có sẵn. Khởi động lại backend để áp dụng migration rồi chạy lại app.

Kiểm thử gồm phân quyền, thao tác đọc riêng từng tài khoản, thông báo chung, thông báo từ tin/hợp đồng trên PostGIS riêng, lọc/phân trang, lỗi mạng, huy hiệu, vòng đời cập nhật, xác nhận gửi và giao diện nhiều kích thước.
