import json
from pathlib import Path
from models import SearchFilters, SearchPlan
from llm_client import analyze_with_llm
from text_utils import normalize
from entities import extract_numbers, extract_type, extract_location, extract_amenities, extract_lifestyle, remove_filters


LOCATIONS = json.loads((Path(__file__).parent / "data/locations.json").read_text(encoding="utf-8-sig"))


def analyze_message(request):
    plan = analyze_with_llm(request)
    original = request.context.model_copy(deep=True)
    if plan.action == "RESET":
        return SearchPlan(action="RESET", clarification="NONE", filters=SearchFilters())
    if plan.action != "SEARCH" or plan.clarification == "DETAILS":
        return SearchPlan(action=plan.action, clarification=plan.clarification, filters=original)
    values = original.model_dump()
    values.update(plan.filters.model_dump(exclude_unset=True))
    text = normalize(request.message).split(" thay vi ")[0]
    try:
        remove_filters(text, values)
        extract_type(text, values)
        extract_numbers(text, values)
        extract_location(text, LOCATIONS, values)
        extract_amenities(text, request.amenityNames, values)
        extract_lifestyle(text, values)
        available = {normalize(name): name for name in request.amenityNames + original.amenities}
        selected = []
        for name in values["amenities"]:
            if normalize(name) not in available:
                raise ValueError("Tiện ích không có trong danh mục")
            selected.append(available[normalize(name)])
        values["amenities"] = list(dict.fromkeys(selected))
        if "re hon" in text:
            if original.maxPrice is None:
                raise ValueError("Cần ngân sách để hiểu rẻ hơn")
            values["maxPrice"] = original.maxPrice
            values["sort"] = "PRICE_ASC"
        return SearchPlan(action="SEARCH", clarification=plan.clarification, filters=SearchFilters(**values))
    except ValueError:
        return SearchPlan(action="SEARCH", clarification="DETAILS", filters=original)
