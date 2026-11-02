# Thống kê và báo cáo Admin

Mở mục **Thống kê & báo cáo** trên website Admin. Mặc định xem từ đầu tháng đến hôm nay; có chọn khoảng ngày, nút 30 ngày gần nhất, làm mới và xuất Excel. Khoảng tối đa 366 ngày, tính cả hai ngày đầu/cuối.

## Dữ liệu và cách tính

- Member mới: tài khoản có vai trò MEMBER, theo users.created_at. Không tính Admin.
- Tin mới: số bản ghi listings tạo trong kỳ, bao gồm tin ẩn/đã xóa mềm để không mất số liệu đã phát sinh.
- Hợp đồng mới: số hợp đồng tạo trong kỳ, gồm các trạng thái; không đồng nghĩa số hợp đồng đã ký.
- Doanh thu dịch vụ: tổng payment_transactions.amount có trạng thái SUCCESS, theo transaction_date. Không gồm giao dịch PENDING/FAILED, tiền thuê hay tiền cọc. Giao dịch gói miễn phí có giá trị 0 vẫn được tính vào số giao dịch thành công.
- transaction_date hiện là ngày tạo giao dịch; hệ thống chưa lưu ngày quyết toán riêng. Khoảng ngày dùng giá trị timestamp đang lưu trong hệ thống, không tự chuyển múi giờ.
- Trạng thái tin/hợp đồng là trạng thái hiện tại của các bản ghi tạo trong kỳ; không tái dựng trạng thái lịch sử tại ngày kết thúc báo cáo.
- Biểu đồ tháng chỉ cộng những ngày thuộc khoảng đã chọn; tháng đầu/cuối có thể chưa đủ tháng. Chi tiết ngày có đủ cả ngày không phát sinh (số 0).

Không hiển thị các số liệu mẫu như lượt truy cập, tỷ lệ chuyển đổi, tăng trưởng hoặc tỷ lệ lấp đầy vì chưa có dữ liệu đo tương ứng.

## Excel

Xuất file .xlsx gồm Tổng quan, Theo ngày và Trạng thái. Bộ lọc ngày giống báo cáo đang xem, số tiền là ô số. File được truy vấn lại tại thời điểm xuất, vì vậy dữ liệu có thể mới hơn màn hình nếu có phát sinh đồng thời. Không có dữ liệu vẫn xuất được báo cáo số 0.

## API

Chỉ ADMIN được gọi cả hai API:

- GET /api/v1/admin/reports?from=YYYY-MM-DD&to=YYYY-MM-DD
- GET /api/v1/admin/reports/export?from=YYYY-MM-DD&to=YYYY-MM-DD

Ngày thiếu/sai, đảo ngược hoặc vượt 366 ngày trả 400. SQL tổng hợp tại cơ sở dữ liệu; mỗi báo cáo đọc trong cùng giao dịch để các nhóm số liệu nhất quán. Không thay đổi bảng hay dữ liệu hiện có.

## Kiểm thử thủ công

1. Khởi động lại backend và website Admin để tải tính năng mới.
2. Chọn kỳ có dữ liệu và đối chiếu với danh sách người dùng/tin/hợp đồng tạo trong kỳ.
3. Đối chiếu doanh thu với giao dịch SUCCESS; PENDING và FAILED không được cộng.
4. Xuất Excel, kiểm tra khoảng ngày, tổng số và chi tiết theo ngày.
5. Chọn kỳ không có dữ liệu: số 0 và thông báo trống, không có số liệu minh họa.
6. Ngắt kết nối backend, nhấn làm mới: hiện lỗi, vô hiệu hóa xuất; kết nối lại và nhấn thử lại.

Kiểm thử tự động SQL dùng schema PostGIS riêng, không ghi vào dữ liệu đang sử dụng.
