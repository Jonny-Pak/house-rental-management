package com.rental.modules.chatbot;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

public record ChatFilters(
    @Pattern(regexp = "WHOLE_HOUSE|BOARDING_ROOM|SHARED_ROOM") String listingType,
    @Size(max = 120) String locationText,
    @DecimalMin("0") @DecimalMax("1000000000") BigDecimal minPrice,
    @DecimalMin("0") @DecimalMax("1000000000") BigDecimal maxPrice,
    @DecimalMin("0") @DecimalMax("1000000") BigDecimal minArea,
    @DecimalMin("0") @DecimalMax("1000000") BigDecimal maxArea,
    @Min(0) @Max(100) Integer bedrooms,
    Boolean allowPets,
    Boolean allowSmoking,
    @Pattern(regexp = "ANY|MALE|FEMALE") String genderPreference,
    @Size(max = 5) List<@NotBlank @Size(max = 80) String> amenities,
    @Size(max = 3) List<@NotBlank @Size(max = 80) String> keywords,
    @DecimalMin("0.1") @DecimalMax("50") Double radiusKm,
    @Pattern(regexp = "NEWEST|PRICE_ASC|AREA_DESC") String sort
) {
    public ChatFilters {
        amenities = amenities == null ? List.of() : List.copyOf(amenities);
        keywords = keywords == null ? List.of() : List.copyOf(keywords);
        sort = sort == null ? "NEWEST" : sort;
    }

    public static ChatFilters empty() {
        return new ChatFilters(null, null, null, null, null, null, null, null, null, null, null, null, null, "NEWEST");
    }
}
