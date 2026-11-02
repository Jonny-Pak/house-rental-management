# Tìm nhà theo bán kính và khoảng cách

## Cách sử dụng

1. Mở Thuê nhà, Thuê phòng trọ, Tìm người ở ghép hoặc Bản đồ, rồi mở Bộ lọc.
2. Trong Tìm quanh một vị trí, chọn tâm bằng địa chỉ, GPS hoặc chạm bản đồ. Xác nhận Dùng vị trí này.
3. Chọn bán kính từ 0,1 đến 50 km. Mặc định 3 km khi chọn vị trí lần đầu; sắp xếp tự chuyển sang Gần nhất.
4. Có thể kết hợp giá, diện tích, loại nhà, khu vực và giới tính ở ghép. Nhấn Áp dụng.
5. Danh sách và bảng xem nhanh trên bản đồ hiển thị khoảng cách. Bản đồ vẽ vòng tròn tìm kiếm và đánh dấu tâm; marker tin vẫn chỉ có icon nhà.
6. Bỏ giới hạn bán kính để trở lại tìm thông thường. Chuyển bản đồ sang danh sách giữ bộ lọc và vị trí.

Khoảng cách là đường chim bay theo mô hình hình cầu, không phải quãng đường đi xe. Tin thiếu tọa độ không nằm trong kết quả tìm theo bán kính. Tin chờ duyệt, bị từ chối, đã ẩn, đã thuê hoặc đã xóa không được trả về.

GPS cần bật dịch vụ vị trí và cấp quyền; khi bị từ chối, hết thời gian hoặc thiết bị không hỗ trợ, vẫn có thể chọn tâm trên bản đồ. Tìm địa chỉ dùng dịch vụ geocoding của nền tảng; nếu không tìm được thì chọn trực tiếp trên bản đồ. Hủy chọn vị trí hoặc hủy bộ lọc giữ nguyên tìm kiếm đang dùng.

## Thao tác trực tiếp trên bản đồ

Trong Bản đồ nhà cho thuê, bấm **Tìm theo bán kính** ngay dưới thanh tìm kiếm. App bắt đầu tìm quanh tâm bản đồ đang xem, mặc định 3 km. Không tự yêu cầu GPS khi bật chức năng.

- Chạm vào vùng trống trên bản đồ để chuyển tâm; chạm icon nhà vẫn mở chi tiết tin.
- Nhập địa điểm ở ô riêng rồi bấm kính lúp để chuyển tâm đến địa chỉ đó.
- Bấm nút vị trí hiện tại để dùng GPS. Khi bị từ chối quyền hoặc không lấy được vị trí, giữ tâm cũ và cho phép thử lại hoặc chọn trên bản đồ.
- Kéo thanh bán kính để thay đổi phạm vi. Chỉ tải lại kết quả khi thả thanh kéo.
- Bấm **Tắt tìm theo bán kính** để bỏ giới hạn khoảng cách, giữ từ khóa và các bộ lọc giá/loại nhà/khu vực.
- Chuyển sang danh sách giữ nguyên tâm và bán kính. Xóa bộ lọc trong lúc đang lấy GPS không cho kết quả GPS đến muộn bật lại tìm theo bán kính.

Vùng điều khiển hỗ trợ cuộn trên cửa sổ thấp, chữ lớn hoặc khi mở bàn phím.

## Backend

GET `/api/v1/listings/public/nearby?latitude=10.78&longitude=106.7&radiusKm=3`

API công khai chỉ trả tin đã duyệt và còn trống, sắp xếp theo khoảng cách tăng dần và mã tin khi bằng nhau. Bắt buộc đủ ba tham số. Tọa độ phải hữu hạn, vĩ độ trong [-90, 90], kinh độ trong [-180, 180], bán kính trong [0.1, 50]. Dữ liệu không hợp lệ trả HTTP 400.

PostGIS dùng ST_DWithin với geography và bán kính tính bằng mét, cùng ST_Distance để sắp xếp. Chọn mô hình hình cầu đồng nhất với cách hiển thị khoảng cách trên app. Tham số truyền qua repository, không ghép chuỗi SQL từ dữ liệu nhập.

Migration V23 bổ sung chỉ mục geography cho tin công khai; không thay đổi hoặc xóa dữ liệu hiện có. Khởi động lại backend để Flyway áp dụng migration, sau đó khởi động lại app.

## Kiểm thử

- `ListingWorkflowTest`: dữ liệu không hợp lệ và đổi km sang mét.
- `ListingSecurityTest`: truy cập công khai, thiếu tham số và sai kiểu số.
- `ListingPostgisTest#nearbySearchUsesMetersAndExcludesNonPublicListings`: PostGIS thật trong schema thử nghiệm riêng; kiểm tra gần/xa, sát ranh giới, thiếu tọa độ và trạng thái tin.
- `nearby_search_test.dart`: khoảng cách, sắp xếp, kết hợp bộ lọc, yêu cầu cũ không ghi đè yêu cầu mới, lỗi mạng/thử lại, chọn địa chỉ/GPS/bản đồ, xóa giới hạn và chuyển bản đồ sang danh sách.
- `rental_filter_test.dart`, `listing_map_layout_test.dart`: hồi quy bộ lọc và bản đồ.

Các kiểm thử không cần dùng GPS, địa chỉ hoặc tài khoản thật. Kiểm thử PostGIS bật bằng biến RENTAL_POSTGIS_TESTS=true và tự dọn schema thử nghiệm.
