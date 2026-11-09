from typing import List, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field, model_validator


class SearchFilters(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)
    listingType: Optional[Literal["WHOLE_HOUSE", "BOARDING_ROOM", "SHARED_ROOM"]] = None
    locationText: Optional[str] = Field(default=None, max_length=120)
    minPrice: Optional[float] = Field(default=None, ge=0, le=1_000_000_000)
    maxPrice: Optional[float] = Field(default=None, ge=0, le=1_000_000_000)
    minArea: Optional[float] = Field(default=None, ge=0, le=1_000_000)
    maxArea: Optional[float] = Field(default=None, ge=0, le=1_000_000)
    bedrooms: Optional[int] = Field(default=None, ge=0, le=100)
    allowPets: Optional[bool] = None
    allowSmoking: Optional[bool] = None
    genderPreference: Optional[Literal["ANY", "MALE", "FEMALE"]] = None
    amenities: List[str] = Field(default_factory=list, max_length=5)
    keywords: List[str] = Field(default_factory=list, max_length=3)
    radiusKm: Optional[float] = Field(default=None, ge=0.1, le=50)
    sort: Literal["NEWEST", "PRICE_ASC", "AREA_DESC"] = "NEWEST"

    @model_validator(mode="after")
    def check_ranges(self):
        if self.minPrice is not None and self.maxPrice is not None and self.minPrice > self.maxPrice:
            raise ValueError("Khoảng giá không hợp lệ")
        if self.minArea is not None and self.maxArea is not None and self.minArea > self.maxArea:
            raise ValueError("Khoảng diện tích không hợp lệ")
        for text in self.amenities + self.keywords:
            if not text.strip() or len(text) > 80:
                raise ValueError("Điều kiện tìm kiếm không hợp lệ")
        return self


class AnalyzeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    message: str = Field(min_length=1, max_length=1000)
    context: SearchFilters = Field(default_factory=SearchFilters)
    locationName: Optional[str] = Field(default=None, max_length=200)
    amenityNames: List[str] = Field(default_factory=list, max_length=200)


class SearchPlan(BaseModel):
    model_config = ConfigDict(extra="forbid")
    action: Literal["SEARCH", "HELP", "UNSUPPORTED", "RESET"]
    clarification: Literal["NONE", "LOCATION", "DETAILS"]
    filters: SearchFilters
