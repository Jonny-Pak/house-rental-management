# Admin quản lý nội dung hệ thống

Website Admin → **Nội dung hệ thống** (`/content`) quản lý 5 trang có sẵn: Giới thiệu, Quy định, Hướng dẫn sử dụng, Liên hệ và Hướng dẫn báo sự cố. Các trang được gắn với nút tương ứng trên trang chủ app.

## Luồng sử dụng

1. Chọn trang cần sửa; nhập tiêu đề và nội dung tiếng Việt. Nội dung dạng văn bản, chia đoạn bằng xuống dòng, tối đa 20.000 ký tự; tiêu đề tối đa 150 ký tự.
2. **Lưu nháp** giữ nội dung đang soạn. Người dùng vẫn thấy bản đã xuất bản trước đó.
3. **Xem trước** hiển thị nội dung đang nhập, không lưu hoặc xuất bản. **Xem bản công khai** tải đúng bản người dùng đang thấy, giữ nguyên nội dung đang soạn.
4. **Xuất bản** có xác nhận, đồng thời lưu và công bố nội dung đang nhập. Không cần lưu nháp trước.
5. **Gỡ xuất bản** có xác nhận; người dùng không xem được trang đó nữa. Nội dung soạn thảo được giữ lại để xuất bản lại. Nếu đang sửa chưa lưu, lưu nháp trước khi gỡ xuất bản.
6. Chuyển trang bằng menu Admin hoặc nút tải lại nội dung khi chưa lưu sẽ hỏi trước khi bỏ thay đổi. Lỗi lưu giữ nguyên văn bản để sửa/thử lại.
7. App mở nội dung từ máy chủ khi người dùng chọn mục thông tin. Có nút tải lại và thông báo/thử lại nếu trang chưa được công bố hoặc không kết nối được.

Mỗi lần cập nhật có phiên bản. Khi hai Admin cùng sửa, yêu cầu có phiên bản cũ trả 409; không ghi đè bản mới. Admin cần tải lại rồi chỉnh sửa tiếp.

## API

| Quyền | Phương thức | Đường dẫn | Nội dung |
| --- | --- | --- | --- |
| Công khai | GET | `/api/v1/content/{slug}` | Chỉ trả `slug`, `title`, `body`, `publishedAt` của bản đã xuất bản |
| Admin | GET | `/api/v1/admin/content` | Danh sách trang và trạng thái nháp/xuất bản |
| Admin | GET | `/api/v1/admin/content/{slug}` | Bản soạn thảo, phiên bản và thời gian cập nhật |
| Admin | PUT | `/api/v1/admin/content/{slug}` | Lưu nháp: `title`, `body`, `version` |
| Admin | POST | `/api/v1/admin/content/{slug}/publish` | Lưu và xuất bản: `title`, `body`, `version` |
| Admin | POST | `/api/v1/admin/content/{slug}/unpublish` | Gỡ xuất bản: `version` |

`slug` cố định: `about`, `rules`, `guide`, `contact`, `support`. Không tạo/xóa tùy ý các trang đã gắn với menu app. Trang chưa công bố hoặc không tồn tại trả 404; dữ liệu sai trả 400. Member và khách không được truy cập API quản lý. Nội dung hiển thị dưới dạng văn bản, không thực thi HTML.

## Áp dụng và kiểm tra

- Khởi động lại backend để Flyway chạy **V19**; dữ liệu thông tin hiện có được khởi tạo thành 5 trang đã xuất bản, không sửa migration cũ.
- Chạy lại website Admin và app để dùng trang quản lý và các liên kết thông tin mới.
- Sửa Giới thiệu và lưu nháp; app tải lại vẫn phải thấy bản cũ. Xuất bản, app tải lại phải thấy bản mới.
- Gỡ xuất bản; app phải thông báo nội dung chưa công bố. Xuất bản lại phải xem được.
- Mở cùng một trang ở hai phiên Admin, lưu ở phiên thứ nhất, phiên thứ hai phải báo xung đột và giữ nội dung đang soạn.
- Thử tiêu đề/nội dung trống, chữ tiếng Việt, nhiều đoạn dài, màn hình hẹp và chữ phóng to.
- Mục Hướng dẫn báo sự cố chỉ quản lý bài hướng dẫn; không tự tạo chức năng gửi báo cáo hay gửi email.

Kiểm thử backend dùng schema PostGIS riêng; kiểm thử giao diện dùng dữ liệu giả, không sửa nội dung thật đang sử dụng.
