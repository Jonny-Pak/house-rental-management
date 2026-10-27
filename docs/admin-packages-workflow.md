# Admin quản lý gói dịch vụ

Website Admin → **Gói dịch vụ**. Trang quản lý riêng với trang xem/mua gói trên app Member.

## Danh mục

- Tìm tên, lọc Đang bán/Ngừng bán, phân trang 20 gói.
- Thêm hoặc sửa tên (20 ký tự), giá nguyên VND (0–99.999.999), số lượt đăng thường/VIP/làm mới (mỗi loại 0–32.767), mô tả (255 ký tự), trạng thái bán.
- Tên gói không được trùng, không phân biệt hoa thường. Gói phải có ít nhất một lượt quyền lợi.
- Giá 0 là gói miễn phí, giữ luồng mua miễn phí hiện có.
- Ngừng bán ẩn gói khỏi danh sách Member và chặn yêu cầu mua mới kể cả khi app còn giữ dữ liệu cũ. Có thể mở bán lại.
- Chỉ xóa gói chưa có người mua hoặc giao dịch. Gói đã sử dụng cần ngừng bán để giữ lịch sử.
- Mỗi thao tác sửa/trạng thái/xóa gửi version. Nếu Admin khác đã cập nhật, tải lại danh sách và mở form mới để tiếp tục; form lỗi giữ nguyên dữ liệu nhập.

## Quyền lợi đã mua và giao dịch đang chờ

Mỗi giao dịch mới lưu riêng mã gói, tên và số lượt tại thời điểm tạo thanh toán. Số tiền được lưu trong amount. Kết quả thanh toán cấp lượt từ thông tin đã lưu, không đọc lại quyền lợi mới trong danh mục. Vì vậy Admin sửa giá/tên/lượt hoặc ngừng bán trong lúc người dùng thanh toán không đổi giao dịch đang chờ.

Kết quả trả về được kiểm tra chữ ký và số tiền. Khóa giao dịch khi xử lý và chỉ cấp lượt một lần; nhận lại kết quả SUCCESS không cộng lặp. Giao dịch đang chờ vẫn được hoàn tất khi gói đã ngừng bán.

Tên gói đã mua lưu riêng ở user_subscriptions, để Profile giữ tên tại lần mua gần nhất khi Admin đổi tên danh mục. Số dư lượt dùng INTEGER để tránh tràn SMALLINT khi cộng nhiều lần mua. Giữ cách cộng dồn và mốc quota_reset_at 30 ngày của luồng mua hiện có.

Migration bổ sung thông tin cho giao dịch cũ theo mã gói trong vnpay_transaction_ref ở thời điểm cập nhật. Với dữ liệu cũ không xác định được mã gói, không tự suy đoán quyền lợi để cấp thêm lượt.

## API

Chỉ Admin:

- GET /api/v1/admin/memberships?query=&active=true&page=0
- POST /api/v1/admin/memberships
- PUT /api/v1/admin/memberships/{id}
- PATCH /api/v1/admin/memberships/{id}/status: active, version
- DELETE /api/v1/admin/memberships/{id}?version=...

Member:

- GET /api/v1/memberships: chỉ gói đang bán, sắp theo giá và mã.
- POST /api/v1/payments/create: packageId hợp lệ 1–32.767.

GET /api/v1/payments/vnpay-return nhận kết quả từ cổng thanh toán, không yêu cầu JWT; chữ ký vẫn bắt buộc và được kiểm tra trong PaymentService.

## Áp dụng và kiểm thử

Khởi động lại backend để Flyway chạy **V22__admin_membership_packages.sql**, rồi chạy lại website/app. Migration giữ các gói và lượt hiện có, bổ sung trạng thái, version và thông tin mua; không sửa migration cũ.

1. Admin tạo gói, kiểm tra app tải lại thấy đúng giá và số lượt.
2. Sửa và ngừng bán: app tải lại không còn gói; gọi mua từ dữ liệu cũ phải bị chặn.
3. Mua gói miễn phí, đổi tên/quyền lợi của gói: Profile và lượt đã mua phải giữ thông tin cũ.
4. Tạo giao dịch trả phí rồi sửa/ngừng bán gói. Kết quả có chữ ký và số tiền đúng vẫn cấp lượt theo thông tin lúc mua, gọi lại không cộng thêm.
5. Xóa gói chưa dùng; thử xóa gói có giao dịch phải nhận thông báo ngừng bán thay vì xóa.
6. Kiểm tra tên trùng, số âm/số lẻ/vượt giới hạn, phiên bản cũ, lọc/phân trang và lỗi mạng.

Kiểm thử backend dùng schema PostGIS riêng. Kiểm thử thanh toán dùng kết quả có chữ ký giả lập, không phát sinh giao dịch ngân hàng thật.
