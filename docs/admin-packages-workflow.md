# Admin quản lý gói dịch vụ

Website Admin → **Gói dịch vụ**. Trang quản lý riêng với trang xem/mua gói trên app Member.

## Danh mục

- Tìm tên, lọc Đang bán/Ngừng bán, phân trang 20 gói.
- Thêm hoặc sửa tên (20 ký tự), giá nguyên VND (0–99.999.999), số lượt đăng tin/nâng VIP/làm mới (mỗi loại 0–32.767), mô tả (255 ký tự), trạng thái bán.
- Tên gói không được trùng, không phân biệt hoa thường. Gói phải có ít nhất một lượt quyền lợi.
- Gói Cơ bản là gói mặc định, tự cấp một lần sau khi Member xác thực OTP thành công; đăng nhập Google thành công cũng cấp nếu chưa có gói. Không cần bấm đăng ký gói.
- Gói mặc định luôn miễn phí và hoạt động; không thể xóa, ngừng bán hoặc chuyển thành trả phí. Admin có thể sửa quyền lợi cho tài khoản được cấp mới, không đổi số lượt của tài khoản đã được cấp.
- Giá 0 ở các gói khuyến mãi khác vẫn dùng luồng đăng ký miễn phí.
- Ngừng bán ẩn gói khỏi danh sách Member và chặn yêu cầu mua mới kể cả khi app còn giữ dữ liệu cũ. Có thể mở bán lại.
- Chỉ xóa gói chưa có người mua hoặc giao dịch. Gói đã sử dụng cần ngừng bán để giữ lịch sử.
- Mỗi thao tác sửa/trạng thái/xóa gửi version. Nếu Admin khác đã cập nhật, tải lại danh sách và mở form mới để tiếp tục; form lỗi giữ nguyên dữ liệu nhập.

## Quyền lợi đã mua và giao dịch đang chờ

Mỗi giao dịch mới lưu riêng mã gói, tên và số lượt tại thời điểm tạo thanh toán. Số tiền được lưu trong amount. Kết quả thanh toán cấp lượt từ thông tin đã lưu, không đọc lại quyền lợi mới trong danh mục. Vì vậy Admin sửa giá/tên/lượt hoặc ngừng bán trong lúc người dùng thanh toán không đổi giao dịch đang chờ.

Kết quả trả về được kiểm tra chữ ký và số tiền. Khóa giao dịch khi xử lý và chỉ cấp lượt một lần; nhận lại kết quả SUCCESS không cộng lặp. Giao dịch đang chờ vẫn được hoàn tất khi gói đã ngừng bán.

Tên gói đã mua lưu riêng ở user_subscriptions, để Profile giữ tên tại lần mua gần nhất khi Admin đổi tên danh mục. Số dư lượt dùng INTEGER để tránh tràn SMALLINT khi cộng nhiều lần mua. Cộng dồn khi gói còn hạn; lượt hết hạn không được cộng lại. Gói mua thêm có hạn 30 ngày từ lúc thanh toán thành công. Chi tiết áp dụng lượt: [Quyền lợi gói dịch vụ](subscription-benefits-workflow.md).

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

Gói mặc định trả thêm `defaultPackage: true` trong API danh mục. App hiển thị “Gói mặc định”, không có nút đăng ký; API thanh toán chặn đăng ký lại gói này để lấy thêm lượt. Hết lượt miễn phí không tự cộng lại khi đăng nhập.

Migration **V24__default_membership.sql** đánh dấu gói miễn phí đầu tiên làm gói mặc định và cấp cho Member đã xác thực, đang hoạt động, chưa có bản ghi gói. Tài khoản đã có gói và số lượt cũ được giữ nguyên. Mỗi người dùng chỉ có một bản ghi số dư gói; lịch sử mua nằm ở giao dịch thanh toán. Gói mặc định không đặt ngày hết hạn, các lần mua nâng cấp vẫn giữ cách cộng dồn hiện có.

GET /api/v1/payments/vnpay-return nhận kết quả từ cổng thanh toán, không yêu cầu JWT; chữ ký vẫn bắt buộc và được kiểm tra trong PaymentService.

## Áp dụng và kiểm thử

Khởi động lại backend để Flyway chạy các migration mới, gồm **V24__default_membership.sql**, rồi chạy lại website/app. Migration giữ các gói và lượt hiện có; không sửa migration cũ.

1. Admin tạo gói, kiểm tra app tải lại thấy đúng giá và số lượt.
2. Sửa và ngừng bán: app tải lại không còn gói; gọi mua từ dữ liệu cũ phải bị chặn.
3. Đăng ký tài khoản, xác thực OTP: Profile có gói Cơ bản và số lượt đúng danh mục. Đăng nhập lại hoặc dùng hết lượt không được cấp lặp. Đổi tên/quyền lợi của gói: Profile và lượt đã cấp phải giữ thông tin cũ.
4. Tạo giao dịch trả phí rồi sửa/ngừng bán gói. Kết quả có chữ ký và số tiền đúng vẫn cấp lượt theo thông tin lúc mua, gọi lại không cộng thêm.
5. Xóa gói chưa dùng; thử xóa gói có giao dịch phải nhận thông báo ngừng bán thay vì xóa.
6. Kiểm tra tên trùng, số âm/số lẻ/vượt giới hạn, phiên bản cũ, lọc/phân trang và lỗi mạng.

Kiểm thử backend dùng schema PostGIS riêng. Kiểm thử thanh toán dùng kết quả có chữ ký giả lập, không phát sinh giao dịch ngân hàng thật.
