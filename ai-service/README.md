# Rental local chatbot

Mô hình nhỏ tự huấn luyện: TF-IDF ký tự + Logistic Regression. Phân tích tiếng Việt thành điều kiện tìm nhà, không gọi Gemini hoặc API mô hình bên ngoài.

Từ thư mục này:

```powershell
.\.venv\Scripts\python.exe train.py
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8001
```

Xem [hướng dẫn dữ liệu, huấn luyện, vận hành và đánh giá](../docs/chatbot-workflow.md). File `data/train.json` là nơi bổ sung câu tự chuẩn bị. Khởi động lại dịch vụ sau khi huấn luyện lại.
