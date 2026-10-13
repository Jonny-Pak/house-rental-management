# Quản lý hợp đồng thuê

Chủ nhà mở **Chức năng → Quản lý hợp đồng → Tạo hợp đồng**, chọn một tin
đã duyệt đang cho thuê của mình, nhập email hoặc số điện thoại tài khoản người thuê và tìm tài
khoản. Sau khi chọn ngày bắt đầu/kết thúc, tiền thuê, tiền cọc và ghi chú,
hợp đồng được lưu ở trạng thái `DRAFT` (chờ người thuê xác nhận).

Người thuê đăng nhập tài khoản tương ứng, mở Quản lý hợp đồng, xem chi tiết
và đồng ý hoặc từ chối. Chỉ người thuê trong hợp đồng được xác nhận.
Chủ nhà có thể sửa hoặc hủy bản nháp. Hai bên không thể sửa nội dung
hợp đồng đã có hiệu lực. Chủ nhà có thể kết thúc hợp đồng đang hiệu lực.

Các trạng thái: `DRAFT → ACTIVE → TERMINATED` hoặc `EXPIRED`;
`DRAFT → CANCELLED` khi hủy/từ chối. Hợp đồng `ACTIVE` quá ngày kết thúc
được chuyển `EXPIRED` khi một trong hai bên mở danh sách/chi tiết hợp đồng.
Tính ngày theo múi giờ Việt Nam.

Khi xác nhận, tin đăng chuyển `RENTED` và biến mất khỏi danh sách/bản đồ
công khai. Khi kết thúc/hết hạn, tin còn trạng thái `RENTED` chuyển `HIDDEN`;
chủ nhà kiểm tra rồi chủ động hiển thị lại. Không tự đăng lại tin.
Một tin chỉ có một hợp đồng `DRAFT` hoặc `ACTIVE` theo luồng mới.
Các thao tác cùng tin được khóa ở database để tránh tạo/xác nhận trùng.
Tin có hợp đồng đang hiệu lực không thể sửa, xóa hoặc đổi trạng thái trực
tiếp từ Quản lý tin đăng; quản lý hợp đồng trước.

Tên và địa chỉ tin được lưu tại thời điểm tạo hợp đồng; không thay đổi theo
các chỉnh sửa tin sau này. Trước xác nhận/hủy/kết thúc, client gửi `version`
đã xem; nếu bản nháp thay đổi, API trả 409 và yêu cầu tải lại, kiểm tra.

API xác thực:

- `GET /contracts/me`, `GET /contracts/{id}`: chỉ hai bên của hợp đồng.
- `GET /contracts/tenant?email=...&listingId=...` hoặc `?phone=...&listingId=...`: tra cứu email hoặc số điện thoại chính xác,
  chỉ chủ sở hữu tin; trả ID và tên, không trả hồ sơ tài khoản.
- `POST /contracts`: tạo bản nháp, trả 201.
- `PUT /contracts/{id}`: chủ nhà sửa bản nháp, không đổi tin.
- `PATCH /contracts/{id}/status`: `{ "status": "ACTIVE|CANCELLED|TERMINATED", "version": 0 }`.

Các URL trên có tiền tố `/api/v1`. DTO phản hồi gồm thông tin hợp đồng,
tên hai bên, `myRole` và `version`; không tuần tự hóa entity User/Listing.
Admin không tự có quyền xem/sửa hợp đồng của người khác.

Khởi động lại backend để Flyway áp dụng `V11__contract_management.sql`,
sau đó Hot Restart Flutter. Migration giữ nguyên các hợp đồng hiện có,
bổ sung ghi chú, phiên bản, địa chỉ/tên tin đã lưu và các trạng thái mới.
Kiểm thử backend dùng schema PostGIS riêng; kiểm thử Flutter dùng repository
giả để kiểm tra quyền thao tác, xác nhận đúng phiên bản và nhập tiền.
