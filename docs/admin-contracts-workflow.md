# Admin tra cứu hợp đồng

## Sử dụng

Đăng nhập website bằng tài khoản Admin → Hợp đồng thuê. Trang này lấy toàn bộ hợp đồng trong hệ thống qua API riêng, không dùng danh sách hợp đồng của tài khoản đang đăng nhập.

- Tìm mã hợp đồng (ví dụ `#12`), tiêu đề/địa chỉ tin thuê, tên, email hoặc số điện thoại của hai bên. Tìm kiếm cũng nhận tên và số điện thoại đã chốt trong nội dung hợp đồng.
- Lọc trạng thái: chờ người thuê xác nhận, đang hiệu lực, hết hạn, kết thúc, hủy. Lọc loại thuê nhà hoặc phòng trọ.
- Mỗi trang 20 hợp đồng, xếp mã mới nhất trước. Thay bộ lọc hoặc tìm kiếm trở về trang đầu.
- Xem chi tiết: tin thuê, địa chỉ, thời hạn, tiền thuê, tiền cọc, hai bên, thông tin xác nhận, ghi chú và bản nội dung đã lưu. Có thể sao chép nội dung để đối chiếu khi hỗ trợ.

Admin chỉ tra cứu. Tạo/sửa bản nháp, xác nhận, hủy và kết thúc vẫn dùng luồng của các bên tham gia hợp đồng. Trang Admin không cung cấp các nút này và không có API ghi tương ứng.

## API

- `GET /api/v1/admin/contracts?query=&status=&type=&page=0`: danh sách phân trang; status/type trống để lấy tất cả.
- `GET /api/v1/admin/contracts/{id}`: chi tiết gồm thông tin đã lưu của các bên và văn bản hợp đồng.
- Cả hai yêu cầu vai trò ADMIN và trả `Cache-Control: no-store`. Member và người chưa đăng nhập không được truy cập.
- Danh sách không trả văn bản và dữ liệu giấy tờ chi tiết; chỉ trang chi tiết trả các trường này. API hợp đồng Member vẫn kiểm tra người tham gia như trước.

Trạng thái ACTIVE có ngày kết thúc trước ngày hiện tại tại Asia/Ho_Chi_Minh được hiển thị và lọc như EXPIRED. Tra cứu Admin không tự cập nhật trạng thái trong cơ sở dữ liệu, không đổi trạng thái tin thuê và không phát sinh thông báo. Luồng hết hạn hiện có của Member vẫn được giữ.

Không cần migration mới. Khởi động lại backend và website sau khi cập nhật mã nguồn.

## Kiểm thử

`ListingPostgisTest.adminContractSearchPaginationDetailsAndExpiredViewAreReadOnly` dùng schema PostGIS riêng: kiểm tra phạm vi toàn hệ thống, tìm kiếm, phân trang, dữ liệu cũ, trạng thái hết hạn và không ghi dữ liệu/thông báo. `ListingSecurityTest` kiểm tra Admin/Member, cache và API ghi không được hỗ trợ. `frontend/test/admin_contracts_test.dart` kiểm tra tìm/lọc/phân trang, trang chi tiết, tải lại khi lỗi và màn hình 320 px với chữ phóng lớn.
