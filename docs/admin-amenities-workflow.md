# Admin quản lý nội thất và tiện ích

Website Admin → **Nội thất & tiện ích** (`/amenities`).

## Danh mục

- Hai nhóm: Nội thất (`FURNITURE`) và Tiện ích (`UTILITY`).
- Thêm/sửa tên tối đa 100 ký tự, mô tả tối đa 255 ký tự, trạng thái cho phép chọn mới.
- Tên không được trùng trong cùng nhóm, không phân biệt chữ hoa/thường.
- Tìm tên, lọc nhóm/trạng thái, phân trang 20 mục. Có thể mở sử dụng lại mục đã ngừng.
- Chỉ xóa mục chưa có tin sử dụng. Mục đã được chọn trong tin phải ngừng sử dụng để giữ dữ liệu, kể cả khi tin đã xóa mềm.
- Mục đã có tin sử dụng không được chuyển nhóm. Admin vẫn có thể sửa tên/mô tả.
- Mỗi lần sửa, đổi trạng thái và xóa đều kiểm tra phiên bản. Xung đột yêu cầu tải lại; form giữ dữ liệu khi lưu lỗi.

## Kết nối với tin đăng

1. Chủ nhà tạo tin → bước Chi tiết bất động sản → chọn các mục trong **Nội thất & tiện ích**. Không bắt buộc, tối đa 30 mục.
2. Bản xem trước hiển thị các tên đã chọn. Sau khi gửi, Admin thấy các mục này trong màn duyệt tin.
3. Khi tin được duyệt, người thuê thấy nội thất/tiện ích trên trang chi tiết.
4. Chủ nhà sửa tin có thể thêm, bỏ từng mục hoặc bỏ hết. Lưu tin vẫn chuyển về chờ duyệt lại như trước.
5. Mục ngừng sử dụng không xuất hiện trong danh sách chọn mới. Tin đã chọn vẫn giữ thông tin; khi sửa có thể giữ hoặc bỏ mục cũ, không được thêm mục ngừng dùng vào tin khác.
6. Lỗi tải danh mục có nút thử lại, không tự xóa các lựa chọn đang có.

Trường tình trạng nội thất `FULL/BASIC/EMPTY` hiện có vẫn được giữ. Không tự suy đoán rằng tin cũ có giường, tủ lạnh… từ trường này.

## Excel

File xuất và file mẫu có thêm cột tùy chọn **Mã nội thất/tiện ích** sau các cột chỉ xem, và sheet **NoiThatTienIch** để tra mã đang được phép chọn. Các mã cách nhau bằng dấu phẩy, ví dụ `1,9`.

File mẫu cũ vẫn nhập được. Mã sai, trùng, ngừng sử dụng hoặc vượt giới hạn được báo lỗi trong bước xem trước; file lỗi không nhập một phần.

## API

- `GET /api/v1/amenities`: danh mục đang sử dụng, cho phép truy cập công khai.
- `GET /api/v1/admin/amenities?query=&category=&active=&page=0`: chỉ Admin.
- `POST /api/v1/admin/amenities`: thêm mới.
- `PUT /api/v1/admin/amenities/{id}`: cập nhật kèm `version`.
- `PATCH /api/v1/admin/amenities/{id}/status`: `active`, `version`.
- `DELETE /api/v1/admin/amenities/{id}?version=...`: xóa mục chưa sử dụng.

Tin đăng gửi `amenityIds: [1,9]`. Gửi `[]` để bỏ hết; không gửi trường này thì cập nhật từ client cũ vẫn giữ lựa chọn hiện có. Phản hồi tin đăng có danh sách `amenities` gồm tên, nhóm và trạng thái danh mục.

## Áp dụng

Khởi động lại backend để Flyway chạy **V25__amenities.sql**, sau đó Hot Restart app và tải lại web Admin. Migration chỉ tạo danh mục, bảng liên kết và dữ liệu mẫu; không thay đổi tin cũ.

Kiểm thử backend dùng schema PostGIS riêng; kiểm thử giao diện dùng repository giả để kiểm tra CRUD, lỗi mạng, lựa chọn cũ, xác nhận thao tác và cỡ chữ lớn.
