# Gửi và xử lý báo cáo sự cố

## Người dùng

Mở **Trang chủ → Báo cáo sự cố** hoặc **Tài khoản → Báo cáo sự cố của tôi**.

- Xem danh sách báo cáo của chính mình, tìm kiếm, lọc trạng thái/loại sự cố và chuyển trang.
- Chọn **Gửi báo cáo mới**, nhập loại sự cố, tiêu đề (tối đa 150 ký tự), mô tả (tối đa 5.000 ký tự).
- Sau khi gửi, ứng dụng mở chi tiết và lịch sử xử lý. Có nút **Hướng dẫn báo sự cố** để đọc bài do Admin quản lý.
- Các loại: tài khoản, tin đăng, hợp đồng, thanh toán, lỗi ứng dụng, khác.
- Tối đa một báo cáo mới trong 60 giây cho mỗi người dùng. Mỗi lần mở form có mã gửi riêng; gửi lại cùng mã/nội dung trả về báo cáo đã tạo để tránh trùng khi mạng lỗi.
- Người dùng không thể đọc, sửa hoặc xóa báo cáo của người khác, không tự thay đổi trạng thái xử lý.

## Admin

Website Admin → **Báo cáo sự cố** → **Xem và xử lý**.

- Xem tất cả báo cáo, tìm theo tiêu đề, mô tả hoặc tên người gửi; lọc loại/trạng thái, phân trang 20 báo cáo.
- Chọn **Đang xử lý**, **Đã giải quyết** hoặc **Từ chối**, nhập phản hồi (bắt buộc, tối đa 2.000 ký tự) và xác nhận gửi.
- Mỗi phản hồi được thêm vào lịch sử với người xử lý, trạng thái, nội dung và thời gian. Có thể gửi phản hồi bổ sung cùng trạng thái.
- Báo cáo đã đóng có thể mở lại bằng **Đang xử lý**, kèm lý do. Muốn chuyển từ Đã giải quyết sang Từ chối (hoặc ngược lại), mở lại trước.
- Nếu Admin khác đã cập nhật, API trả 409 và giữ nội dung đang nhập. Nhấn **Thử tải lại**, xem lịch sử mới rồi xử lý tiếp.
- Không có thao tác xóa lịch sử báo cáo/phản hồi.

## Thông báo

Admin đang hoạt động/đã xác thực nhận thông báo khi có báo cáo mới. Người gửi nhận thông báo sau mỗi phản hồi xử lý. Chọn **Xem báo cáo** trong thông báo sẽ mở đúng mã báo cáo; quyền truy cập vẫn được kiểm tra trên backend.

Thông báo được lưu cùng giao dịch cơ sở dữ liệu với báo cáo/phản hồi. Không gửi email hoặc thông báo đẩy ngoài ứng dụng trong luồng này.

## API

Yêu cầu đăng nhập cho mọi API:

- POST /api/v1/incidents: requestKey, title, category, description.
- GET /api/v1/incidents/me: query, status, category, page (từ 0).
- GET /api/v1/incidents/{id}: chỉ chủ báo cáo.
- GET /api/v1/admin/incidents: chỉ Admin, cùng bộ lọc.
- GET /api/v1/admin/incidents/{id}: chỉ Admin.
- PATCH /api/v1/admin/incidents/{id}: status, message, version; chỉ Admin.

Trạng thái: OPEN, IN_PROGRESS, RESOLVED, REJECTED. Loại: ACCOUNT, LISTING, CONTRACT, PAYMENT, TECHNICAL, OTHER.

Backend tự lấy người gửi/người xử lý từ tài khoản đăng nhập; bỏ qua mọi reporterId/adminId do client tự gửi. Nội dung hiển thị dạng văn bản, không thực thi HTML. Báo cáo chưa có ảnh đính kèm; người gửi mô tả chi tiết trong form.

## Áp dụng và kiểm thử

Khởi động lại backend để Flyway áp dụng **V21__incident_reports.sql**, rồi chạy lại app/website Admin. Migration tạo bảng báo cáo, lịch sử và liên kết thông báo; không sửa migration cũ hay dữ liệu tin/hợp đồng hiện có.

1. Member gửi báo cáo; kiểm tra báo cáo chỉ xuất hiện trong danh sách của người gửi.
2. Admin nhận thông báo, mở đúng báo cáo và phản hồi Đang xử lý.
3. Member nhận thông báo và đọc được lịch sử.
4. Admin giải quyết hoặc từ chối, thử mở lại; lịch sử cũ phải còn nguyên.
5. Hai Admin cùng mở: phiên lưu sau phải báo xung đột nếu đang giữ version cũ.
6. Thử lỗi mạng, báo cáo trống, tìm kiếm/lọc/phân trang và màn hình hẹp.

Kiểm thử tích hợp dùng schema PostGIS riêng; không thay đổi dữ liệu đang sử dụng.
