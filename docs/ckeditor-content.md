# Soạn thảo nội dung bằng CKEditor

Admin web → Nội dung hệ thống → chọn trang. Dùng thanh công cụ tiếng Việt để định dạng tiêu đề, phông/cỡ/màu chữ, căn lề, danh sách, liên kết và bảng. Lưu nháp không thay đổi bản công khai. Xem trước kiểm tra bố cục; Xuất bản cập nhật nội dung trên app.

CKEditor 5.49.0.1 được đóng gói và lưu trong `frontend/web/vendor/ckeditor5`, không tải từ CDN khi sử dụng. Không cần Node để chạy Flutter. Khi cập nhật CKEditor, vào `frontend/tools/ckeditor`, chạy `npm ci` và `npm run build`. Giữ tệp LICENSE.md đi kèm.

Cấu hình mặc định là `licenseKey: GPL`, chỉ dành cho việc sử dụng đáp ứng GPL. Không tự thay đổi giấy phép của toàn bộ dự án. Nếu dùng giấy phép thương mại tự lưu trữ, truyền khóa được cấp qua `--dart-define=CKEDITOR_LICENSE_KEY=...` khi build web. Khóa frontend không phải bí mật. Xem https://ckeditor.com/docs/ckeditor5/latest/getting-started/licensing/license-key-and-activation.html.

Nội dung định dạng được lưu dưới dạng HTML trong các cột TEXT hiện có; không cần migration mới. Backend lọc thẻ, thuộc tính và CSS được phép trước khi lưu. Không hỗ trợ upload ảnh, nhúng iframe hoặc script. Giới hạn 20.000 ký tự bao gồm mã định dạng. Nội dung cũ dạng văn bản vẫn giữ xuống dòng và được hiển thị như trước.

Ứng dụng người dùng và bản xem trước dùng cùng bộ hiển thị HTML, hỗ trợ bảng và liên kết HTTP/HTTPS/email. Thư viện `html` cố định ở 0.15.6 để tương thích với `flutter_html` 3.0.0.

Kiểm thử: ContentHtmlTest kiểm tra lọc HTML; ListingPostgisTest kiểm tra lưu nháp/xuất bản định dạng; system_content_test.dart kiểm tra giao diện và bảng trên màn hình nhỏ. Kiểm tra CKEditor thực tế bằng Chrome trước khi hoàn tất.
