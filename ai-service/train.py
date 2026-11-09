import json
from pathlib import Path
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, f1_score
from sklearn.pipeline import Pipeline
from text_utils import normalize

ROOT = Path(__file__).parent
LABELS = ["search", "refine", "help", "reset", "unsupported", "unknown"]


def read_data(name):
    data = json.loads((ROOT / "data" / (name + ".json")).read_text(encoding="utf-8-sig"))
    texts, labels = [], []
    for label, sentences in data.items():
        if label not in LABELS or not isinstance(sentences, list):
            raise ValueError("Nhãn hoặc danh sách câu không hợp lệ: " + label)
        for sentence in sentences:
            if not isinstance(sentence, str) or not sentence.strip():
                raise ValueError("Câu dữ liệu bị trống hoặc sai kiểu")
            texts.append(normalize(sentence))
            labels.append(label)
    return texts, labels


def predict(model, texts, threshold):
    results = []
    for probabilities in model.predict_proba(texts):
        index = probabilities.argmax()
        label = model.classes_[index]
        results.append(label if probabilities[index] >= threshold else "unknown")
    return results


def train():
    train_x, train_y = read_data("train")
    valid_x, valid_y = read_data("validation")
    test_x, test_y = read_data("test")
    all_texts = train_x + valid_x + test_x
    if len(set(all_texts)) != len(all_texts):
        raise ValueError("Có câu trùng sau chuẩn hóa. Tách lại dữ liệu trước khi huấn luyện.")
    if "unknown" in train_y:
        raise ValueError("unknown dành cho kiểm tra khả năng từ chối, không phải nhãn huấn luyện")
    model = Pipeline([
        ("tfidf", TfidfVectorizer(analyzer="char_wb", ngram_range=(2, 5))),
        ("classifier", LogisticRegression(C=4, max_iter=1000, class_weight="balanced", random_state=42)),
    ])
    model.fit(train_x, train_y)
    threshold, best_score = 0.35, -1
    for candidate in [0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60]:
        score = f1_score(valid_y, predict(model, valid_x, candidate), labels=LABELS, average="macro", zero_division=0)
        if score > best_score:
            threshold, best_score = candidate, score
    predicted = predict(model, test_x, threshold)
    report = {
        "method": "Character TF-IDF (2-5) + Logistic Regression",
        "data_source": "Manually authored synthetic Vietnamese seed sentences; not real user evaluation",
        "split_sizes": {"train": len(train_x), "validation": len(valid_x), "test": len(test_x)},
        "threshold": threshold,
        "validation_macro_f1": best_score,
        "test": classification_report(test_y, predicted, labels=LABELS, output_dict=True, zero_division=0),
        "labels": LABELS,
        "confusion_matrix": confusion_matrix(test_y, predicted, labels=LABELS).tolist(),
        "errors": [],
    }
    for sentence, expected, actual in zip(test_x, test_y, predicted):
        if expected != actual:
            report["errors"].append({"text": sentence, "expected": expected, "actual": actual})
    folder = ROOT / "artifacts"
    folder.mkdir(exist_ok=True)
    joblib.dump({"model": model, "threshold": threshold}, folder / "intent.joblib")
    (folder / "evaluation.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"splits": report["split_sizes"], "threshold": threshold, "test_macro_f1": report["test"]["macro avg"]["f1-score"], "errors": len(report["errors"])}))


if __name__ == "__main__":
    train()
