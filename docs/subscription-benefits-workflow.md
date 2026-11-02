# Áp dụng quyền lợi gói dịch vụ

## Quy tắc

- Tài khoản Member đang hoạt động và đã xác thực mới sử dụng quyền lợi. Gói Cơ bản được cấp một lần; đăng nhập lại không nạp lại lượt.
- Mỗi tin mới sử dụng 1 lượt đăng tin. Tin chỉ xuất hiện công khai sau khi Admin duyệt. Nhập Excel cũng trừ 1 lượt cho mỗi tin; vượt số lượt còn lại thì toàn bộ lần nhập được hoàn tác, không mất lượt và không tạo tin một phần.
- Sửa, ẩn, đánh dấu đã thuê và xóa tin không trừ thêm lượt. Tin bị từ chối hoặc bị xóa không hoàn lượt đăng.
- Một lượt nâng VIP áp dụng cho một tin đã duyệt, còn trống và thuộc tài khoản hiện tại. Tin đang VIP không thể nâng lại để tránh mất lượt. VIP có hạn tối đa 30 ngày, không vượt hạn sử dụng gói tại thời điểm nâng.
- Một lượt làm mới cập nhật thời điểm hiển thị của tin. Mỗi tin được làm mới một lần trong 24 giờ. Chỉ áp dụng cho tin đã duyệt, còn trống và không có hợp đồng hiệu lực.
- Danh sách mặc định ưu tiên VIP còn hạn, sau đó sắp xếp theo lần làm mới gần nhất hoặc ngày tạo tin. Khi người thuê chọn sắp xếp giá, diện tích hoặc khoảng cách, hệ thống tôn trọng lựa chọn đó.
- Sửa tin VIP vẫn gửi duyệt lại; thời hạn VIP không được kéo dài thêm. Tin ẩn/đã thuê/chờ duyệt không hiển thị công khai dù còn VIP.
- Gói mua thêm có hạn 30 ngày từ lúc thanh toán thành công. Nếu gói hiện tại còn hạn, cộng lượt còn dư và gia hạn 30 ngày từ lúc thanh toán. Nếu đã hết hạn, lượt cũ không được cộng lại. Thay đổi giá/quyền lợi hoặc ngừng bán gói trên Admin không sửa số lượt đã cấp.
- Gói Cơ bản không có ngày hết hạn nhưng không tự nạp lại lượt.

## Sử dụng trên app

1. Vào **Gói dịch vụ** hoặc **Quản lý tin đăng**, bấm biểu tượng quyền lợi ở góc phải để xem gói, số lượt còn lại và hạn sử dụng.
2. Đăng tin như bình thường. Nếu hết lượt, thông báo yêu cầu đăng ký thêm gói; bản nháp vẫn được giữ trên màn hình.
3. Sau khi tin được duyệt, mở menu thao tác trên tin → **Nâng VIP · 1 lượt** hoặc **Làm mới tin · 1 lượt** → xác nhận sử dụng lượt.
4. Giao diện tải lại tin sau khi thành công và hiển thị nhãn VIP khi còn hạn. Bấm tải lại quyền lợi để xem số lượt mới nhất.
5. Nút tải lại danh sách trên thanh tiêu đề chỉ đọc dữ liệu, không sử dụng lượt làm mới tin.

## API và kiểm soát dữ liệu

- `GET /api/v1/memberships/me`: quyền lợi của tài khoản đang đăng nhập; số lượt khả dụng trả về 0 khi gói hết hạn.
- `POST /api/v1/listings`: tạo tin và trừ lượt trong cùng giao dịch.
- `POST /api/v1/listings/{id}/vip`: nâng VIP và trừ lượt trong cùng giao dịch.
- `POST /api/v1/listings/{id}/refresh`: làm mới và trừ lượt trong cùng giao dịch.
- Backend lấy chủ tài khoản từ phiên đăng nhập, không nhận `ownerId` từ nội dung yêu cầu. Khóa dòng người dùng khi sử dụng quyền lợi hoặc cộng lượt thanh toán để tránh dùng cùng một lượt cho hai yêu cầu đồng thời.
- Sử dụng các cột hiện có; không sửa migration cũ hay xóa dữ liệu.

## Kiểm thử

Kiểm thử với PostGIS trong schema riêng: hết lượt, sửa/xóa không nạp lại lượt, hết hạn và mua lại, hạn VIP, thời gian chờ làm mới, tin không công khai, quyền sở hữu, hai yêu cầu tranh lượt cuối, hoàn tác nhập Excel và thứ tự hiển thị. Kiểm thử Flutter bao gồm xác nhận/hủy, báo lỗi/thử lại, số lượt thực tế, nhãn VIP, lọc/sắp xếp và màn hình nhỏ.
