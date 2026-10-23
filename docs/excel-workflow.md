# Import / Export Excel

Mở **Quản lý tin đăng** hoặc **Hợp đồng thuê**, chọn biểu tượng bảng Excel trên thanh tiêu đề.

## Sử dụng

1. Chọn **Tải file mẫu**. Giữ nguyên tên sheet và hàng tiêu đề.
2. Điền dữ liệu và đọc sheet **HuongDan**. File mẫu tin đăng có sheet **KhuVuc** để tra ID phường/xã; file hợp đồng có **TinCuaToi** để tra mã tin.
3. Chọn **Chọn file và kiểm tra**. Bước này chưa tạo dữ liệu.
4. Sửa các dòng được báo lỗi rồi chọn lại file. Chỉ khi không còn lỗi mới có thể **Xác nhận nhập**.
5. Sau khi nhập thành công, danh sách được tải lại. Tin mới chờ Admin duyệt; hợp đồng mới có trạng thái DRAFT, chờ người thuê xác nhận.

**Xuất Excel** xuất toàn bộ tin của tài khoản hiện tại hoặc hợp đồng mà tài khoản là một trong hai bên. Bộ lọc trên danh sách không áp dụng cho file xuất. Người thuê có thể xuất hợp đồng của mình; giao diện nhập hợp đồng nằm trong chế độ chủ nhà.

## Quy tắc

- Chỉ nhận `.xlsx`, tối đa **5 MB / 500 dòng dữ liệu**. Bỏ qua dòng trống. Không dùng công thức Excel hay file đặt mật khẩu.
- Nhập tạo dữ liệu mới, không sửa dữ liệu cũ. Các cột trạng thái và ID bản ghi chỉ để xem khi xuất.
- Nếu có một dòng lỗi, chưa nhập bất kỳ dòng nào. Quá trình ghi dùng giao dịch; lỗi trong quá trình ghi sẽ hoàn tác cả đợt nhập.
- Tin trùng tiêu đề và địa chỉ với tin đang quản lý hoặc dòng khác trong file bị từ chối.
- Link ảnh tin đăng: 1–10 URL HTTPS, phân cách bằng `|`. Nhập toạ độ thật; mã khu vực phải thuộc danh sách hệ thống.
- Hợp đồng chỉ được tạo cho tin thuộc tài khoản hiện tại, đã duyệt, còn trống, chưa có hợp đồng DRAFT/ACTIVE. Một tin chỉ có một dòng hợp đồng trong file.
- Người thuê được tìm bằng số điện thoại tài khoản. Định dạng điện thoại và giấy tờ tùy thân là **Text** để giữ số 0 đầu.
- Ngày hợp đồng dùng `yyyy-MM-dd` hoặc ô ngày Excel; tiền dùng số VND, không kèm đơn vị hoặc dấu phân cách hàng nghìn.
- Các điều khoản bắt buộc phải có; các cột điều khoản không bắt buộc dùng mặc định của mẫu hợp đồng trong ứng dụng khi để trống. Tên/số điện thoại các bên lấy từ tài khoản; không tự ký hoặc kích hoạt hợp đồng.

## API

Hai nhóm API đều yêu cầu đăng nhập:

| Thao tác | Tin đăng | Hợp đồng |
| --- | --- | --- |
| Tải mẫu | `GET /api/v1/listings/excel/template` | `GET /api/v1/contracts/excel/template` |
| Xuất | `GET /api/v1/listings/excel/export` | `GET /api/v1/contracts/excel/export` |
| Kiểm tra | `POST /api/v1/listings/excel/preview` | `POST /api/v1/contracts/excel/preview` |
| Nhập | `POST /api/v1/listings/excel/import` | `POST /api/v1/contracts/excel/import` |

POST nhận multipart trường `file`. Danh tính chủ nhà lấy từ phiên đăng nhập, không lấy từ Excel hay tham số gửi lên. API kiểm tra và nhập trả `totalRows`, `importedRows`, `rows`, `errors`; mỗi lỗi kèm số dòng Excel.

## Kiểm thử

- `ListingExcelTest`, `ContractExcelTest`: file mẫu, kiểu dữ liệu, giới hạn, lỗi dòng, trùng dữ liệu, số điện thoại và nội dung xuất.
- `ListingSecurityTest`: đăng nhập và sử dụng đúng danh tính trong phiên.
- `ListingPostgisTest`: nhập/xuất tin, duyệt tin, nhập hợp đồng và kiểm tra trạng thái trên schema PostGIS riêng, không dùng dữ liệu ứng dụng hiện có.
- `frontend/test/excel_test.dart`: tải/lưu file, kiểm tra trước khi nhập, xác nhận, lỗi thay đổi dữ liệu, hủy chọn file, quyền giao diện người thuê, chữ lớn và nhiều cỡ màn hình.
