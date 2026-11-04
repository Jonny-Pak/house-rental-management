# Chatbot tìm nhà chạy nội bộ

Chatbot dùng mô hình **TF-IDF ký tự + Logistic Regression** do dự án tự huấn luyện. Không dùng mô hình đã huấn luyện của bên ngoài, không gọi Gemini và không cần API key AI. Đây là chatbot có phạm vi nghiệp vụ, không phải mô hình ngôn ngữ sinh văn bản.

## Luồng xử lý

Backend kiểm tra phạm vi trước khi gọi mô hình hoặc dịch vụ dữ liệu: chỉ tìm tin công khai và hướng dẫn các chức năng hiện có. Các câu ngoài phạm vi, yêu cầu SQL, khóa bí mật, thông tin riêng tư, thao tác tạo/sửa/xóa hoặc giao dịch được từ chối và giữ nguyên điều kiện đang tìm. Hướng dẫn cách thao tác tại màn hình tương ứng không thực hiện thao tác thay người dùng.

1. App gửi câu hỏi, bộ lọc hiện tại và điểm người dùng chọn tới Spring Boot.
2. Backend xác thực tài khoản và giới hạn 12 yêu cầu/phút.
3. Python nhận câu hỏi, bộ lọc và danh mục tiện ích công khai qua API nội bộ có khóa kết nối. Không nhận JWT, hồ sơ riêng hoặc danh sách tin.
4. Mô hình phân loại năm ý định: tìm mới, chỉnh điều kiện, trợ giúp, bắt đầu lại, chức năng ngoài phạm vi. Điểm tin cậy thấp được coi là chưa hiểu; điểm này không phải xác suất đảm bảo câu trả lời đúng.
5. Các hàm Python tách loại nhà, giá, diện tích, số phòng ngủ, khu vực, bán kính và tiện ích thành JSON. Điều kiện sai hoặc chưa hỗ trợ sẽ yêu cầu làm rõ khi phát hiện được.
6. Java kiểm tra JSON và tìm tin **đã duyệt, còn trống**. Tìm quanh điểm sử dụng PostGIS. Chỉ trả tối đa năm thẻ tin, tổng kết quả thật và lời trả lời theo mẫu.
7. App giữ bộ lọc cho câu tiếp theo. Câu “Bắt đầu lại” xóa bộ lọc và điểm tìm; nút cuộc trò chuyện mới xóa thêm các tin nhắn trên màn hình.

Không tự đoán tọa độ, không tự nới ngân sách, không tạo tin nhà giả. Không có kết quả thì người dùng chủ động đổi điều kiện. Điện thoại chỉ kết nối backend; Python không cần mở ra Internet.

## Chạy trên máy hiện tại

Tại thư mục `ai-service`, huấn luyện rồi mở dịch vụ:

```powershell
.\.venv\Scripts\python.exe train.py
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8001
```

Giữ terminal này mở. Khởi động backend và app như bình thường ở terminal khác. Backend mặc định gọi `http://127.0.0.1:8001`. Nếu backend đã chạy trước lúc cập nhật, cần khởi động lại để nhận mã mới. Không có migration mới.

`GET http://127.0.0.1:8001/health` phải trả `provider: local` và `configured: true`. Mô hình thiếu hoặc không tải được thì trả 503 kèm hướng dẫn huấn luyện; backend vẫn có thể khởi động, riêng chatbot chưa dùng được.

## Cài trên máy mới

Python 3.9–3.12 phù hợp bộ phiên bản được ghim trong `requirements.txt`. Cần Internet khi cài thư viện lần đầu; huấn luyện và phục vụ sau đó chạy nội bộ trên CPU.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe train.py
```

Chỉ sao chép `.env.example` khi chưa có `.env`. Điền chuỗi riêng vào `AI_SERVICE_TOKEN` trong `.env`, đặt cùng giá trị cho `app.chatbot.service-token` trong file riêng `backend/config/local-secrets.properties` hoặc biến môi trường `AI_SERVICE_TOKEN` của backend. Không đưa khóa nội bộ vào Git. Cấu hình riêng đã tồn tại trên máy hiện tại được giữ nguyên; các dòng cấu hình Gemini đã được bỏ.

Đặt `AI_SERVICE_URL` nếu Python chuyển sang địa chỉ khác. Nếu hai dịch vụ trên hai máy, dùng mạng riêng hoặc HTTPS. Chỉ tải file joblib do chính mình huấn luyện từ nguồn tin cậy.

## Dữ liệu và cách huấn luyện lại

- `ai-service/data/train.json`: 105 câu mẫu dùng để học trọng số.
- `ai-service/data/validation.json`: 36 câu dùng để chọn ngưỡng tin cậy.
- `ai-service/data/test.json`: 42 câu để đánh giá sau khi chọn ngưỡng.
- `ai-service/data/locations.json`: danh sách hỗ trợ nhận tên khu vực, lấy từ dữ liệu hành chính sẵn có trong dự án, bổ sung vài tên khu vực thông dụng. Tên khác có thể tách sau “ở”, “tại”, “khu vực”; tìm theo văn bản địa chỉ, không phải bộ định vị toàn quốc.

Các file câu mẫu là JSON gồm tên nhãn và danh sách câu, ví dụ:

```json
{
  "search": ["Tìm phòng trọ dưới 4 triệu ở Thủ Đức"],
  "refine": ["Bỏ yêu cầu máy lạnh"],
  "help": ["Bạn giúp được gì"],
  "reset": ["Bắt đầu lại"],
  "unsupported": ["Đổi mật khẩu giúp tôi"]
}
```

Thêm câu vào nhóm đúng trong file hiện có; giữ đủ năm nhãn của tập train. `unknown` chỉ đặt trong validation/test để kiểm tra từ chối câu ngoài phạm vi. Không thêm câu test vào train. Không dùng các câu chỉ thay số hoặc địa chỉ từ cùng một mẫu ở nhiều tập để báo cáo chất lượng; chương trình mới chỉ kiểm tra trùng nguyên câu sau chuẩn hóa, chưa tự phát hiện mọi câu gần giống.

Chạy lại `train.py`, rồi khởi động lại Python để nạp mô hình mới. File `artifacts/intent.joblib` sinh trên máy, được Git bỏ qua. Không cần huấn luyện lại mỗi khi có tin cho thuê mới vì tin được lấy trực tiếp từ database khi tìm.

## Kết quả đánh giá hiện tại

Dữ liệu là **câu mẫu tự biên soạn**, chưa thu thập khảo sát người dùng thật. Ngưỡng chọn trên validation là 0,40. Trên 42 câu test: accuracy **71,43%**, macro-F1 **0,719**; riêng nhãn tìm mới F1 **0,933**. Các số này chỉ đo phân loại ý định, không đo toàn bộ khả năng tách điều kiện hay mức hài lòng của người dùng.

`ai-service/artifacts/evaluation.json` lưu precision/recall/F1 từng nhãn, ma trận nhầm lẫn và 12 câu dự đoán sai, được sinh từ lần chạy thật. Không dùng kết quả mẫu nhỏ này để khẳng định chatbot đã hiểu mọi cách diễn đạt. Muốn làm nghiên cứu chính thức cần bổ sung dữ liệu độc lập, so sánh phương pháp cơ sở và đánh giá trích xuất điều kiện cùng kết quả tìm nhà.

## Câu có thể kiểm tra trên app

- “Tìm phòng trọ dưới 4 triệu ở Thủ Đức có máy lạnh”.
- “Rẻ hơn”: giữ giá trần đã có, sắp giá tăng dần; chưa có giá trần sẽ hỏi lại.
- “Bỏ yêu cầu máy lạnh”: bỏ đúng tiện ích đó.
- “Tìm người ở ghép cho nữ, cho nuôi mèo, không hút thuốc”.
- “Tìm nhà trong bán kính 3 km”: yêu cầu chọn điểm trên bản đồ trước khi tìm.
- “Bắt đầu lại”: xóa điều kiện và điểm đang dùng.

Định dạng tiền hỗ trợ số và đơn vị triệu/tr/k/nghìn/VND, ví dụ `3,5 triệu`, `3tr5`, `3500k`, `4.000.000 VND`, `từ 3 đến 5 triệu`. Giá không có từ “dưới/trên/tối đa/ít nhất” được hiểu là giá chính xác. Nên nhập điều kiện rõ ràng; nhiều ý trái ngược trong một câu hoặc cách diễn đạt chưa có mẫu có thể chưa hiểu đúng.

## API và kiểm thử

### Lưu lịch sử

Migration `V28__chat_history.sql` tạo bảng lịch sử riêng theo tài khoản. Khởi động lại backend để Flyway tự áp dụng migration. Không sửa hoặc xóa các migration cũ.

Mỗi câu hỏi và câu trả lời thành công được lưu cùng thời gian, bộ lọc và điểm tìm kiếm. Khi mở chatbot, app tải 30 lượt gần nhất và khôi phục điều kiện của lượt cuối; nút **Xem tin nhắn cũ hơn** tải các lượt trước mà không thay đổi điều kiện hiện tại. Lịch sử vẫn còn khi đóng app hoặc khởi động lại server. Tin nhắn lỗi chưa nhận được câu trả lời chưa được lưu.

API lấy tài khoản từ JWT, không nhận userId để đọc hoặc xóa lịch sử của người khác. Các thẻ tin trong lịch sử được lấy lại từ danh sách tin công khai hiện tại; tin đã ẩn, xóa hoặc đã thuê không được trả lại. Nội dung trả lời và tổng kết quả là thông tin tại thời điểm trò chuyện, nên có thể khác số thẻ còn công khai khi xem lại.

Nút **Cuộc trò chuyện mới** yêu cầu xác nhận xóa toàn bộ lịch sử của tài khoản trước khi bắt đầu lại. Nếu xóa thất bại, app giữ lịch sử trên màn hình. Câu nhắn **Bắt đầu lại** chỉ đặt lại điều kiện tìm kiếm; các tin nhắn trước đó vẫn nằm trong lịch sử. Việc tự động lưu lịch sử chỉ ghi vào bảng trò chuyện, không cho chatbot quyền sửa dữ liệu tin đăng, hợp đồng hoặc tài khoản.

- `GET /api/v1/chatbot/history?beforeId=...`: trả các lượt theo thứ tự thời gian và `hasMore`; bỏ beforeId để lấy trang mới nhất.
- `DELETE /api/v1/chatbot/history`: xóa lịch sử của tài khoản đang đăng nhập.

- `POST /api/v1/chatbot/messages`: cần JWT; phản hồi `message, filters, conditions, listings, total, locationRequired, clearLocation`.
- `POST /analyze`: API Python nội bộ, cần `X-Service-Token`, chỉ trả kế hoạch có kiểu dữ liệu, không gọi SQL.
- `GET /health`: chỉ trạng thái mô hình, không trả khóa nội bộ.

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
```

Backend: `mvn test`; `RENTAL_POSTGIS_TESTS=true` bật kiểm thử PostGIS trên schema riêng. Để kiểm tra Java gọi mô hình thật, mở Python, đặt cùng `AI_SERVICE_TOKEN`, đặt `RENTAL_LOCAL_AI_TESTS=true`, chạy `mvn -Dtest=ChatbotLocalModelTest test`. Kiểm thử này dùng HTTP thật đến Python, dữ liệu tin giả lập trong bộ nhớ; kiểm thử PostGIS riêng xác nhận truy vấn dữ liệu không gian.

Frontend: `flutter test test/chatbot_test.dart test/chatbot_design_test.dart`.

## Phạm vi hiện tại

Lưu lịch sử và khôi phục ngữ cảnh theo tài khoản trong database. Chỉ tìm nhà, phòng và ở ghép; không tự đăng tin, soạn hợp đồng, thanh toán hoặc tư vấn pháp lý. Không lọc theo sự vắng mặt của một tiện ích: câu như “không có máy lạnh” cần làm rõ; “không cần máy lạnh” bỏ yêu cầu đó. Mô hình nhỏ và bộ quy tắc có thể bỏ sót cách nói lạ; người dùng cần kiểm tra các thẻ điều kiện trước khi chọn tin.
