import json
from pathlib import Path
from models import SearchFilters, SearchPlan
from intent_model import classify
from text_utils import normalize
from entities import extract_numbers, extract_type, extract_location, extract_amenities, extract_lifestyle, remove_filters

LOCATIONS = json.loads((Path(__file__).parent / "data" / "locations.json").read_text(encoding="utf-8-sig"))


def analyze_message(request):
    intent, _ = classify(request.message)
    text = normalize(request.message).split(" thay vi ")[0]
    original = request.context.model_copy(deep=True)
    if intent == "reset":
        return SearchPlan(action="RESET", clarification="NONE", filters=SearchFilters())
    if intent in ["help", "unsupported"]:
        return SearchPlan(action=intent.upper(), clarification="NONE", filters=original)
    if intent == "unknown":
        return SearchPlan(action="SEARCH", clarification="DETAILS", filters=original)
    values = original.model_dump()
    try:
        remove_filters(text, values)
        extract_type(text, values)
        extract_numbers(text, values)
        extract_location(text, LOCATIONS, values)
        extract_amenities(text, request.amenityNames, values)
        extract_lifestyle(text, values)
        if any(word in text for word in ["gia tang dan", "gia thap", "re nhat", "re hon"]):
            if "re hon" in text and original.maxPrice is None:
                raise ValueError("Cần ngân sách để hiểu rẻ hơn")
            values["sort"] = "PRICE_ASC"
        if "dien tich lon" in text:
            values["sort"] = "AREA_DESC"
        if "moi nhat" in text:
            values["sort"] = "NEWEST"
        keywords = list(values["keywords"])
        for word, label in [("yen tinh", "yên tĩnh"), ("sach se", "sạch sẽ")]:
            if word in text and label not in keywords:
                keywords.append(label)
        values["keywords"] = keywords
        filters = SearchFilters(**values)
        changed = filters != original
        followup = "da chon diem" in text or "chon diem tren ban do" in text or "xac nhan vi tri" in text
        repeated_search = intent == "search" and filters != SearchFilters()
        if not changed and not followup and not repeated_search:
            return SearchPlan(action="SEARCH", clarification="DETAILS", filters=original)
        return SearchPlan(action="SEARCH", clarification="NONE", filters=filters)
    except ValueError:
        return SearchPlan(action="SEARCH", clarification="DETAILS", filters=original)
