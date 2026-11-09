from functools import lru_cache
from pathlib import Path
import joblib
from text_utils import normalize

MODEL_PATH = Path(__file__).parent / "artifacts" / "intent.joblib"


@lru_cache(maxsize=1)
def load_model():
    if not MODEL_PATH.exists():
        raise RuntimeError("Chưa có mô hình. Chạy python train.py trước khi mở dịch vụ.")
    return joblib.load(MODEL_PATH)


def classify(message):
    saved = load_model()
    model = saved["model"]
    probabilities = model.predict_proba([normalize(message)])[0]
    index = probabilities.argmax()
    label = model.classes_[index]
    confidence = float(probabilities[index])
    if confidence < saved["threshold"]:
        label = "unknown"
    return label, confidence
