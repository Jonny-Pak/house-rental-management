# Admin quản lý khu vực hành chính

Vào website Admin → **Khu vực hành chính** (`/areas`). Chỉ Admin được truy cập các API quản lý.

## Sử dụng

- Tìm theo tên hoặc mã; lọc cấp hành chính, đơn vị trực thuộc và trạng thái. Mỗi trang có 20 khu vực.
- Thêm tỉnh/thành phố, phường, xã hoặc đặc khu. Tỉnh/thành không có cấp trên; phường/xã/đặc khu chọn tỉnh/thành. Phường thuộc quận/huyện cũ vẫn được hỗ trợ để giữ dữ liệu hiện có.
- Quận/huyện cũ được xem và cập nhật nhưng không tạo mới hoặc chuyển khu vực khác thành quận/huyện.
- Mã hệ thống gồm 1–20 chữ, số, dấu gạch ngang hoặc gạch dưới; không trùng mã khác. Không cho trùng tên trong cùng cấp trên.
- Sửa tên và mã. Chỉ đổi cấp hoặc cấp trên khi khu vực chưa có đơn vị con, tin đăng hoặc khu trọ.
- Ngừng sử dụng/kích hoạt có xác nhận. Muốn ngừng sử dụng cấp trên, phải ngừng sử dụng các đơn vị con trước. Muốn kích hoạt đơn vị con, kích hoạt cấp trên trước.
- Chỉ xóa khu vực không có đơn vị con hoặc dữ liệu tham chiếu. Khu vực đã dùng có thể ngừng sử dụng, giữ nguyên ID, tin đăng, khu trọ và hợp đồng.
- Khu vực ngừng sử dụng không còn trong API chọn địa chỉ và file mẫu Excel; backend từ chối đăng tin, tạo khu trọ hoặc nhập tin Excel vào khu vực đó. Tin công khai cũ vẫn xem được.
- Trang Admin tải lại danh sách sau khi lưu, đổi trạng thái hoặc xóa. Lỗi lưu giữ nguyên nội dung biểu mẫu để sửa/thử lại.

## API

Tất cả đường dẫn dưới `/api/v1/admin/areas`:

| Phương thức | Đường dẫn | Nội dung |
| --- | --- | --- |
| GET | `/` | `query`, `type`, `parentId`, `active`, `page` từ 0 |
| GET | `/parents` | Tỉnh/thành và quận/huyện cũ để chọn cấp trên |
| GET | `/{id}` | Thông tin, số đơn vị con, tin đăng và khu trọ tham chiếu |
| POST | `/` | `name`, `code`, `type`, `parentId`; trả 201 |
| PUT | `/{id}` | Cập nhật các trường như POST |
| PATCH | `/{id}/status` | `active`: true/false |
| DELETE | `/{id}` | Xóa khu vực chưa sử dụng |

Dữ liệu không hợp lệ trả 400, không tồn tại trả 404, trùng hoặc còn dữ liệu tham chiếu trả 409. Member/khách bị chặn khỏi API quản lý. API GET `/api/v1/areas/**` vẫn dùng công khai cho việc chọn địa chỉ.

## Áp dụng và kiểm tra

Khởi động lại backend để Flyway chạy **V18** (thêm trạng thái hoạt động, mặc định giữ các khu vực hiện tại hoạt động), rồi chạy lại website Admin. Không sửa migration cũ.

1. Thêm một tỉnh thử và một xã trực thuộc; kiểm tra xã xuất hiện trong mục chọn địa chỉ của app.
2. Thử mã trùng, tên trống, thiếu cấp trên và tự chọn mình làm cấp trên.
3. Ngừng sử dụng xã; tải lại khu vực trên app, xã phải biến mất. Thử gửi ID xã đó trực tiếp/qua Excel phải bị từ chối.
4. Kích hoạt lại xã; app chọn được xã đó.
5. Thêm tin ở xã, thử xóa/đổi cấp trên phải bị chặn. Ngừng sử dụng xã vẫn giữ nguyên tin cũ.
6. Tạo khu vực chưa sử dụng rồi xóa; hủy hộp thoại xác nhận phải giữ nguyên dữ liệu.
7. Dùng tài khoản Member gọi API quản trị phải bị từ chối. Thu nhỏ website để kiểm tra thẻ và hộp thoại.

Kiểm thử tự động dùng schema PostGIS riêng, không sửa dữ liệu ứng dụng đang dùng.
