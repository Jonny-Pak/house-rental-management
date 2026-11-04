import os
import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from main import app
from models import AnalyzeRequest, SearchFilters
from search_parser import analyze_message
from intent_model import classify
from entities import bounds, money, MONEY_UNIT
from train import read_data


class LocalChatbotTest(unittest.TestCase):
    def parse(self, message, context=None, names=None):
        return analyze_message(AnalyzeRequest(message=message, context=context or SearchFilters(),
            amenityNames=names if names is not None else ["Máy lạnh", "WiFi", "Ban công"]))

    def test_real_model_understands_core_intents(self):
        for text, label in [("Tìm phòng trọ dưới 4 triệu", "search"), ("Rẻ hơn", "refine"),
                            ("Bắt đầu lại", "reset"), ("Xin chào", "help"),
                            ("Viết hợp đồng cho tôi", "unsupported"), ("zzqxv 918273", "unknown")]:
            with self.subTest(text=text):
                self.assertEqual(label, classify(text)[0])

    def test_data_has_no_normalized_duplicates_across_splits(self):
        texts = []
        for split in ["train", "validation", "test"]:
            texts.extend(read_data(split)[0])
        self.assertEqual(len(texts), len(set(texts)))

    def test_money_units_ranges_and_upper_lower_bounds(self):
        for text, expected in [("duoi 3,5 trieu", (None, 3500000)), ("tu 3 den 5 trieu", (3000000, 5000000)),
                               ("it nhat 2500k", (2500000, None)), ("gia 4.000.000 vnd", (4000000, 4000000)),
                               ("gia tu 2500k den 4 trieu", (2500000, 4000000))]:
            with self.subTest(text=text):
                self.assertEqual(expected, bounds(text, MONEY_UNIT, money))

    def test_search_combines_real_model_and_all_entities(self):
        plan = self.parse("Tìm phòng trọ dưới 4 triệu ở Thủ Đức có máy lạnh và wifi")
        self.assertEqual("NONE", plan.clarification)
        self.assertEqual("BOARDING_ROOM", plan.filters.listingType)
        self.assertEqual(4000000, plan.filters.maxPrice)
        self.assertEqual("Thủ Đức", plan.filters.locationText)
        self.assertEqual(["Máy lạnh", "WiFi"], plan.filters.amenities)

    def test_followup_keeps_budget_and_removes_only_requested_amenity(self):
        old = SearchFilters(listingType="BOARDING_ROOM", maxPrice=4000000, amenities=["Máy lạnh", "WiFi"])
        cheaper = self.parse("Rẻ hơn", old)
        self.assertEqual(4000000, cheaper.filters.maxPrice)
        self.assertEqual("PRICE_ASC", cheaper.filters.sort)
        removed = self.parse("Bỏ yêu cầu máy lạnh", cheaper.filters)
        self.assertEqual(["WiFi"], removed.filters.amenities)
        self.assertEqual(4000000, removed.filters.maxPrice)
        self.assertEqual(["Máy lạnh", "WiFi"], old.amenities)

    def test_area_bedrooms_and_radius_are_not_prices(self):
        plan = self.parse("Tìm nhà nguyên căn ít nhất 2 phòng ngủ rộng trên 30 m2 trong bán kính 3 km")
        self.assertEqual("NONE", plan.clarification)
        self.assertEqual(2, plan.filters.bedrooms)
        self.assertEqual(30, plan.filters.minArea)
        self.assertEqual(3, plan.filters.radiusKm)
        self.assertIsNone(plan.filters.maxPrice)

    def test_pets_and_gender_are_explicit(self):
        plan = self.parse("Tìm người ở ghép cho nữ, cho nuôi mèo, không hút thuốc")
        self.assertTrue(plan.filters.allowPets)
        self.assertFalse(plan.filters.allowSmoking)
        self.assertEqual("FEMALE", plan.filters.genderPreference)
        self.assertFalse(self.parse("Tìm phòng không cho nuôi chó").filters.allowPets)

    def test_location_followup_and_reset(self):
        old = SearchFilters(radiusKm=3, maxPrice=4000000)
        plan = self.parse("Đã chọn điểm tìm kiếm quanh đây", old)
        self.assertEqual("NONE", plan.clarification)
        self.assertEqual(old, plan.filters)
        reset = self.parse("Bắt đầu lại", old)
        self.assertEqual("RESET", reset.action)
        self.assertEqual(SearchFilters(), reset.filters)

    def test_invalid_ranges_unclear_cheap_and_unknown_preserve_context(self):
        old = SearchFilters(amenities=["WiFi"])
        for text in ["Rẻ hơn", "Tìm phòng từ 5 đến 3 triệu", "Tìm nhà trong bán kính 99 km", "zzqxv 918273"]:
            with self.subTest(text=text):
                plan = self.parse(text, old)
                self.assertEqual("DETAILS", plan.clarification)
                self.assertEqual(old, plan.filters)

    def test_unavailable_or_negated_amenities_are_not_silently_ignored(self):
        self.assertEqual("DETAILS", self.parse("Tìm phòng có máy lạnh", names=[]).clarification)
        self.assertEqual("DETAILS", self.parse("Tìm phòng không có máy lạnh").clarification)

    def test_api_auth_validation_and_entire_request_without_outbound_http(self):
        with patch.dict(os.environ, {"AI_SERVICE_TOKEN": "test-internal"}):
            client = TestClient(app)
            headers = {"X-Service-Token": "test-internal"}
            self.assertEqual(403, client.post("/analyze", json={"message": "Tìm phòng"}).status_code)
            for body in [{"message": " "}, {"message": "x", "context": {"radiusKm": 51}}, {"message": "x", "sql": "select"}]:
                self.assertEqual(422, client.post("/analyze", json=body, headers=headers).status_code)
            with patch("httpx.post", side_effect=AssertionError("Outbound HTTP forbidden")), patch("socket.create_connection", side_effect=AssertionError("Outbound socket forbidden")):
                response = client.post("/analyze", json={"message": "Tìm phòng trọ dưới 4 triệu"}, headers=headers)
                self.assertEqual(200, response.status_code)
                self.assertEqual(4000000, response.json()["filters"]["maxPrice"])
                self.assertEqual("no-store", response.headers["cache-control"])
                self.assertEqual("local", client.get("/health").json()["provider"])
            with patch.dict(os.environ, {"AI_SERVICE_TOKEN": ""}):
                self.assertEqual(503, client.post("/analyze", json={"message": "Tìm phòng"}, headers=headers).status_code)


if __name__ == "__main__":
    unittest.main()
