# Backend

Backend sử dụng Java 21, Spring Boot và PostgreSQL có PostGIS. Cấu trúc database được quản lý thủ công bằng `database.sql`.

## Database đang dùng

Phiên bản này dùng tên bảng và cột tiếng Việt không dấu, ví dụ `nguoi_dung`, `tin_cho_thue`, `ma_nguoi_dung`. Các tên JSON, endpoint và thuộc tính Java vẫn giữ nguyên để app hiện tại tương thích.

Cấu trúc hiện tại có **23 bảng, 217 cột và 36 khóa ngoại**. Sáu bảng không còn dùng đã được loại khỏi file khởi tạo. Các entity/service đang chạy không tham chiếu sáu bảng đó nên không cần đổi tên trường Java hoặc API. Frontend tiếp tục dùng các API nội dung, QR và danh mục tiện ích hiện có.

Với database còn tên tiếng Anh, cần sao lưu và chạy script sau **một lần** trước khi chạy backend mới:

```powershell
psql -h HOST -p PORT -U USER -d DATABASE -X -v ON_ERROR_STOP=1 -f backend/scripts/doi_ten_database_sang_tieng_viet.sql
```

Chạy lệnh từ thư mục gốc dự án. Script chỉ đổi tên bảng, cột và sequence trong schema hiện tại; không xóa hoặc tạo lại bản ghi. Script chạy trong transaction và từ chối chạy lại trên cấu trúc đã chuyển đổi. Dừng backend trước khi chuyển đổi để tránh ứng dụng cũ truy cập sai tên bảng.

Sau khi có cấu trúc 29 bảng tiếng Việt, sao lưu và chạy tiếp:

```powershell
psql -h HOST -p PORT -U USER -d DATABASE -X -v ON_ERROR_STOP=1 -f backend/scripts/rut_gon_database_con_23_bang.sql
```

Script rút gọn kiểm tra cả sáu bảng còn trống trước khi bỏ, khóa bảng trong transaction và dùng `RESTRICT` để dừng nếu còn phụ thuộc ngoài dự kiến. Nếu bảng có dữ liệu, không tự chuyển hoặc xóa dữ liệu đó. Có thể chạy lại trên cấu trúc đã rút gọn.

Không import lại `database.sql` trên database có dữ liệu. Bảng lịch sử migration cũ, nếu có, không còn được backend sử dụng; không cần xóa bảng đó.

Script `scripts/khoi_phuc_ten_database_tieng_anh.sql` chỉ dành cho cấu trúc 29 bảng trước khi rút gọn. Sau khi rút gọn, muốn khôi phục toàn bộ phiên bản cũ phải dùng bản sao lưu tương ứng. Bảng đối chiếu hiện tại nằm ở [docs/database-tieng-viet.md](../docs/database-tieng-viet.md).

## Tạo database mới

1. Tạo một database PostgreSQL trống trên máy hoặc hosting hỗ trợ PostGIS.
2. Từ thư mục gốc dự án, chạy:

```powershell
psql -h HOST -p PORT -U USER -d NEW_DATABASE -X -v ON_ERROR_STOP=1 -f backend/database.sql
```

3. Cấu hình kết nối trong `src/main/resources/application.yml` hoặc bằng các biến môi trường `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`.
4. Từ thư mục `backend`, chạy:

```powershell
mvn spring-boot:run
```

File SQL chứa cấu trúc bảng, ràng buộc, index và dữ liệu mẫu. Không chứa dữ liệu tài khoản, tin đăng, hợp đồng hoặc giao dịch thực tế. SQL chạy trong transaction và từ chối khởi tạo lại nếu schema đã có bảng `users` hoặc `nguoi_dung`.

## Khi thay đổi cấu trúc

- Cập nhật `database.sql` để các lần tạo database mới nhận được cấu trúc mới.
- Với database đã có dữ liệu, sao lưu trước rồi chạy riêng các câu SQL thay đổi cần thiết, ví dụ `ALTER TABLE`. Không chạy lại toàn bộ file khởi tạo.
- Backend giữ `spring.jpa.hibernate.ddl-auto=validate`: chỉ kiểm tra cấu trúc khi khởi động, không tự tạo hoặc sửa bảng.
- Cấu hình riêng được đặt trong `config/local-secrets.properties`, không đưa lên GitHub.

## Kiểm thử

```powershell
mvn test
```

Bật `RENTAL_POSTGIS_TESTS=true` để kiểm thử database thật trên máy. Các kiểm thử tạo schema tạm từ `database.sql` và tự xóa schema tạm sau khi chạy; không khởi tạo lại database ứng dụng.

`VietnameseDatabaseRenameTest` kiểm tra chuyển đổi từ cấu trúc tiếng Anh có dữ liệu, so sánh nội dung toàn bộ 29 bảng, kiểm tra 43 khóa ngoại, chạy khôi phục và kiểm tra sequence tiếp tục cấp mã. File `src/test/resources/database-before-vietnamese.sql` chỉ là dữ liệu nền cho kiểm thử chuyển đổi; không dùng để khởi tạo hệ thống mới.

`DatabaseReductionTest` kiểm tra bước 29 → 23 bảng: từ chối từng bảng có dữ liệu, giữ nguyên cấu trúc khi có phụ thuộc chưa xử lý, bảo toàn dữ liệu 23 bảng, chạy lại an toàn và đối chiếu tên cột/kiểu dữ liệu với bootstrap mới. `ListingPostgisTest` kiểm tra các luồng nghiệp vụ trên cấu trúc 23 bảng.
