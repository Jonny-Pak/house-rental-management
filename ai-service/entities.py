import re
from text_utils import normalize

NUMBER = r"\d+(?:[.,]\d+)*"
MONEY_UNIT = r"(?:trieu|tr(?![a-z])|k(?![a-z])|nghin|ngan|dong|vnd)"


def number(text):
    if re.fullmatch(r"\d{1,3}(?:[.,]\d{3})+", text):
        return float(text.replace(".", "").replace(",", ""))
    return float(text.replace(",", "."))


def money(text, unit):
    value = number(text)
    if unit.startswith("tr"):
        return value * 1_000_000
    if unit in ["k", "nghin", "ngan"]:
        return value * 1000
    return value


def bounds(text, unit, convert):
    match = re.search(r"(?:tu\s+)?(" + NUMBER + r")\s*(" + unit + r")?\s*(?:den|toi|-)\s*(" + NUMBER + r")\s*(" + unit + r")", text)
    if match:
        return convert(match[1], match[2] or match[4]), convert(match[3], match[4])
    match = re.search(r"(" + NUMBER + r")\s*(" + unit + r")", text)
    if not match:
        return None
    value = convert(match[1], match[2])
    prefix = text[max(0, match.start() - 35):match.start()]
    if re.search(r"(?:duoi|toi da|khong qua|toi da thanh|toi da la|muc tran|it hon|thap hon|ngan sach len|muc toi da thanh)\s*$", prefix):
        return None, value
    if re.search(r"(?:tren|it nhat|toi thieu|lon hon|tu)\s*$", prefix):
        return value, None
    return value, value


def extract_numbers(text, values):
    text = re.sub(r"(\d+)tr(\d)(?!\d)", r"\1.\2 trieu", text)
    price = bounds(text, MONEY_UNIT, money)
    if price:
        values["minPrice"], values["maxPrice"] = price
    area = bounds(text, r"(?:m2|m²|met vuong)", lambda value, unit: number(value))
    if area:
        values["minArea"], values["maxArea"] = area
    bedrooms = re.search(r"(\d+)\s*(?:phong ngu|pn\b)", text)
    if bedrooms:
        values["bedrooms"] = int(bedrooms[1])
    radius = re.search(r"(" + NUMBER + r")\s*(km|kilomet|met\b)", text)
    if radius:
        values["radiusKm"] = number(radius[1]) / (1000 if radius[2] == "met" else 1)
    elif any(word in text for word in ["quanh day", "gan day", "gan vi tri", "quanh vi tri"]):
        values["radiusKm"] = values.get("radiusKm") or 3


def extract_type(text, values):
    if any(word in text for word in ["o ghep", "cung phong", "ghep phong", "share phong"]):
        values["listingType"] = "SHARED_ROOM"
    elif any(word in text for word in ["nguyen can", "ca nha", "toan bo nha", "thue nha", "tim nha", "nha thue"]):
        values["listingType"] = "WHOLE_HOUSE"
    elif any(word in text for word in ["phong tro", "nha tro", "thue phong", "tim phong", "phong cho thue", "co phong nao"]):
        values["listingType"] = "BOARDING_ROOM"


AMENITIES = {
    "may lanh": ["may lanh", "dieu hoa"],
    "wifi": ["wifi", "wi-fi", "internet"],
    "ban cong": ["ban cong"],
    "may giat": ["may giat"],
    "thang may": ["thang may"],
    "cho de xe": ["cho de xe", "bai giu xe", "cho dau xe"],
}


def extract_amenities(text, names, values):
    selected = list(values["amenities"])
    names = list(dict.fromkeys(names + selected))
    for key, aliases in AMENITIES.items():
        if any(alias in text for alias in aliases) and not any(normalize(name) in aliases for name in names):
            raise ValueError("Tiện ích được hỏi chưa có trong danh mục đang sử dụng")
    for name in names:
        key = normalize(name)
        aliases = [key]
        for group in AMENITIES.values():
            if key in group:
                aliases = group
                break
        for alias in aliases:
            match = re.search(r"\b" + re.escape(alias) + r"\b", text)
            if not match:
                continue
            prefix = text[max(0, match.start() - 30):match.start()]
            if re.search(r"(?:khong can|khong yeu cau|bo yeu cau|bo dieu kien|bo)\s*$", prefix):
                selected = [item for item in selected if normalize(item) != key]
            elif re.search(r"(?:khong co|khong duoc co)\s*$", prefix):
                raise ValueError("Chưa hỗ trợ lọc loại trừ tiện ích")
            elif name not in selected:
                selected.append(name)
            break
    values["amenities"] = selected


def extract_lifestyle(text, values):
    if any(word in text for word in ["nuoi meo", "nuoi cho", "thu cung", "mang meo", "mang cho"]):
        if re.search(r"(?:khong can|khong yeu cau).*?(?:nuoi|thu cung)", text):
            values["allowPets"] = None
        else:
            values["allowPets"] = not bool(re.search(r"(?:cam|khong cho|khong duoc).*?(?:nuoi|thu cung|mang)", text))
    if "hut thuoc" in text:
        values["allowSmoking"] = not bool(re.search(r"(?:khong|cam).*?hut thuoc", text))
        if "khong yeu cau" in text or "khong can" in text:
            values["allowSmoking"] = None
    if "nam nu" in text or "khong phan biet gioi" in text:
        values["genderPreference"] = "ANY"
    elif values.get("listingType") == "SHARED_ROOM":
        if re.search(r"\bnu\b", text):
            values["genderPreference"] = "FEMALE"
        elif re.search(r"\bnam\b", text):
            values["genderPreference"] = "MALE"


def extract_location(text, locations, values):
    for name in sorted(locations, key=len, reverse=True):
        if re.search(r"\b" + re.escape(normalize(name)) + r"\b", text):
            values["locationText"] = name
            return
    match = re.search(r"\b(?:tai|khu vuc|o)\s+(.+?)(?=\s+(?:co|gia|duoi|tren|cho|trong|tu)\b|[,?.!]|$)", text)
    if match and not match[1].startswith(("ghep", "quanh", "gan", "yen", "sach")):
        values["locationText"] = match[1][:120]


def remove_filters(text, values):
    for phrase in ["bo gioi han gia", "khong gioi han gia", "bo gioi han ve ngan sach"]:
        if phrase in text:
            values["minPrice"] = values["maxPrice"] = None
    if "khong gioi han dien tich" in text or "bo gioi han dien tich" in text:
        values["minArea"] = values["maxArea"] = None
    if "bo ban kinh" in text or "khong gioi han ban kinh" in text:
        values["radiusKm"] = None
    if "bo khu vuc" in text or "khong gioi han khu vuc" in text:
        values["locationText"] = None
    if "bo tat ca tien ich" in text:
        values["amenities"] = []
