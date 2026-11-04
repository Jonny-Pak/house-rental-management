import hmac
import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Response
from models import AnalyzeRequest, SearchPlan
from search_parser import analyze_message
from intent_model import load_model

load_dotenv(Path(__file__).with_name(".env"))
app = FastAPI(title="Rental AI", docs_url=None, redoc_url=None)


@app.get("/health")
def health():
    try:
        load_model()
        return {"status": "UP", "configured": True, "provider": "local", "model": "tfidf-logistic-regression"}
    except (OSError, RuntimeError, ValueError):
        raise HTTPException(503, "Chưa có mô hình nội bộ. Chạy python train.py.")


@app.post("/analyze", response_model=SearchPlan)
def analyze(request: AnalyzeRequest, response: Response, x_service_token: str = Header(default="")):
    expected = os.getenv("AI_SERVICE_TOKEN", "")
    if not expected:
        raise HTTPException(503, "Chưa cấu hình khóa kết nối dịch vụ AI.")
    if not hmac.compare_digest(x_service_token.encode(), expected.encode()):
        raise HTTPException(403, "Không có quyền truy cập dịch vụ AI.")
    if not request.message.strip():
        raise HTTPException(422, "Vui lòng nhập câu hỏi.")
    response.headers["Cache-Control"] = "no-store"
    try:
        return analyze_message(request)
    except (OSError, RuntimeError):
        raise HTTPException(503, "Không tải được mô hình nội bộ. Chạy lại python train.py.")
