# Thanh toán VNPAY trên app

## Luồng sử dụng

1. Member mở **Gói dịch vụ**, chọn đăng ký gói trả phí. Backend lưu giao dịch chờ và chụp lại tên, giá, số lượt của gói trước khi ký URL VNPAY.
2. App mở trình duyệt ngoài và hiển thị màn **Kết quả thanh toán**. Mở được trình duyệt không có nghĩa là đã thanh toán thành công.
3. VNPAY gửi kết quả đã ký về IPN hoặc Return URL. Backend kiểm tra chữ ký, mã merchant, mã giao dịch, số tiền và kết quả ngân hàng. Chỉ kết quả hợp lệ mới cập nhật trạng thái và cấp quyền lợi.
4. IPN có thể xác nhận giao dịch khi người dùng không quay lại trình duyệt. Return URL cũng xử lý kết quả đã ký để hỗ trợ quá trình quay về app. Cả hai dùng chung khóa giao dịch, không cấp lượt hai lần.
5. Trang trả về có nút **Mở ứng dụng** dùng link `houserental://payments/payment-result?reference=...`. Nếu trình duyệt không mở app, người dùng tự quay về app và bấm **Kiểm tra lại**.
6. App chỉ lấy mã giao dịch từ link rồi hỏi backend bằng phiên đăng nhập. Không tin tham số `status=success` trong link. Mã giao dịch của người khác không đọc được.
7. Khi app đang mở màn kết quả, kiểm tra lại mỗi 5 giây, tối đa khoảng 3 phút; dừng khi có kết quả cuối, mất kết nối, ra nền hoặc đóng màn hình. Khi quay lại app sẽ kiểm tra lại. Nút **Kiểm tra lại** luôn cho phép tra cứu thủ công.
8. Thành công → **Hoàn tất** → trở lại luồng gói dịch vụ và tải lại Profile/quyền lợi khi trở về. Nếu app đã bị đóng, nút hoàn tất mở lại trang chính với dữ liệu tài khoản từ backend.
9. Có thể mở **Lịch sử thanh toán** trong Gói dịch vụ để xem 20 giao dịch gần nhất, kể cả giao dịch tạo trước khi app đóng hoặc mất mạng.

## Trạng thái

- `PENDING`: chưa có kết quả xác thực từ ngân hàng.
- `SUCCESS`: đã cấp quyền lợi đúng một lần.
- `CANCELLED`: ngân hàng trả mã `24`; lưu trạng thái `FAILED` và mã phản hồi để nhận diện hủy.
- `FAILED`: giao dịch không thành công, không cấp quyền lợi.
- `EXPIRED`: giao dịch vẫn chờ nhưng đã quá 15 phút. Đây là trạng thái hiển thị; nếu kết quả ngân hàng hợp lệ đến muộn thì vẫn được xác nhận để tránh bỏ sót tiền đã thanh toán.

Nếu người dùng đã bị trừ tiền nhưng chưa có kết quả, hãy kiểm tra lại giao dịch cũ hoặc gửi báo cáo kèm mã giao dịch trước khi tạo thanh toán mới. App không tự hoàn tiền và không tự đánh dấu thành công khi hết thời gian chờ.

## Cấu hình chạy trên điện thoại

Backend phải truy cập được từ trình duyệt trên điện thoại. Nếu để trống `VNPAY_RETURN_URL`, backend tạo Return URL từ địa chỉ của yêu cầu tạo thanh toán, thay vì cố định `localhost` trên điện thoại.

Để VNPAY chủ động gửi IPN, cần một địa chỉ HTTPS công khai trỏ tới backend. Sau khi có địa chỉ đó:

1. Thiết lập merchant Sandbox, mã website và khóa ký VNPAY trong cấu hình backend hiện có. Dùng thông tin Sandbox cho kiểm thử, không dùng tài khoản thanh toán thật.
2. Cấu hình Return URL công khai và khởi động backend từ chính terminal có biến môi trường đó:

```powershell
$env:VNPAY_RETURN_URL = 'https://YOUR-BACKEND/api/v1/payments/vnpay-return'
```

3. Đăng ký IPN URL với VNPAY:

```text
https://YOUR-BACKEND/api/v1/payments/vnpay-ipn
```

4. Chạy app trỏ tới cùng backend, từ thư mục `frontend`:

```powershell
flutter run --dart-define=API_BASE_URL=https://YOUR-BACKEND/api/v1
```

Thay `YOUR-BACKEND` bằng địa chỉ thật. Nếu dùng địa chỉ tạm thời và địa chỉ thay đổi, cần cập nhật cả Return URL, IPN URL và URL API của app.

5. Cài lại hoặc chạy lại app sau khi đổi AndroidManifest/Info.plist; Hot Reload không đăng ký được URL scheme mới. Android và iOS đều đăng ký scheme `houserental`.

Chưa có HTTPS công khai thì vẫn kiểm thử được logic backend/app bằng kiểm thử tự động và kết quả mô phỏng, nhưng chưa xác minh được IPN trực tiếp từ máy chủ VNPAY. Không coi các kiểm thử đó là một giao dịch Sandbox trực tiếp đã thành công.

## API

- `POST /api/v1/payments/create`: yêu cầu đăng nhập, lấy gói từ server, không nhận giá tiền từ app.
- `GET /api/v1/payments/{reference}/status`: yêu cầu đăng nhập, chỉ xem giao dịch của mình, không cache.
- `GET /api/v1/payments/me`: 20 giao dịch gần nhất của tài khoản, không cache.
- `GET /api/v1/payments/vnpay-return`: public, nhận kết quả có chữ ký và hiển thị nút mở app.
- `GET /api/v1/payments/vnpay-ipn`: public, xác thực chữ ký trước khi cập nhật. Trả `RspCode` theo giao thức VNPAY: `00` ghi nhận, `02` đã xử lý, `01` không tìm thấy, `04` sai số tiền, `97` sai chữ ký, `99` lỗi cần thử lại.
- Endpoint chẩn đoán cũ chỉ có trong profile `dev` và bắt buộc quyền Admin.

Migration `V26__vnpay_payment_results.sql` bổ sung mã phản hồi và chỉ mục lịch sử; không sửa migration cũ và không xóa dữ liệu.

## Tài liệu đối chiếu

- [Kết nối thanh toán VNPAY](https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html)
- [Mô hình Return URL và IPN](https://sandbox.vnpayment.vn/apis/docs/mo-hinh-ket-noi/)
- [Flutter deep linking](https://docs.flutter.dev/ui/navigation/deep-linking)
