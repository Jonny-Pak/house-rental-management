package com.rental.modules.chatbot;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rental.modules.amenity.dto.AmenityResponse;
import com.rental.modules.amenity.service.AmenityService;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.service.ListingService;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@EnabledIfEnvironmentVariable(named = "RENTAL_LOCAL_AI_TESTS", matches = "true")
class ChatbotLocalModelTest {
    @Test void javaCallsRealLocalTrainedModelAndSearchesOnlyEligibleListings() {
        try (var validation = Validation.buildDefaultValidatorFactory()) {
            var ai = new ChatbotAiClient("http://127.0.0.1:8001", System.getenv("AI_SERVICE_TOKEN"),
                validation.getValidator(), new ObjectMapper());
            var listings = mock(ListingService.class);
            var amenities = mock(AmenityService.class);
            var coldAir = new AmenityResponse(1L, "Máy lạnh", "UTILITY", "", true, 0L, 0L);
            when(amenities.activeItems()).thenReturn(List.of(coldAir));
            var available = new ListingResponse();
            available.setId(1L);
            available.setTitle("Phòng trọ Thủ Đức");
            available.setAddress("Linh Xuân, Thủ Đức");
            available.setListingType("BOARDING_ROOM");
            available.setRentPrice(BigDecimal.valueOf(3000000));
            available.setApprovalStatus("APPROVED");
            available.setRentalStatus("AVAILABLE");
            available.setAmenities(List.of(coldAir));
            var hidden = new ListingResponse();
            hidden.setApprovalStatus("APPROVED");
            hidden.setRentalStatus("HIDDEN");
            when(listings.getApprovedListings()).thenReturn(List.of(available, hidden));
            var service = new ChatbotService(ai, new ChatbotSearch(listings), amenities);
            var first = service.reply(1L, new ChatRequest("Tìm phòng trọ dưới 4 triệu ở Thủ Đức có máy lạnh", null, null, null, null));
            assertEquals(1, first.total());
            assertEquals(1L, first.listings().getFirst().getId());
            assertEquals(4000000, first.filters().maxPrice().intValue());
            var cheaper = service.reply(1L, new ChatRequest("Rẻ hơn", first.filters(), null, null, null));
            assertEquals("PRICE_ASC", cheaper.filters().sort());
            assertEquals(first.filters().maxPrice(), cheaper.filters().maxPrice());
            var radius = service.reply(1L, new ChatRequest("Tìm nhà trong bán kính 3 km", null, null, null, null));
            assertTrue(radius.locationRequired());
            var reset = service.reply(1L, new ChatRequest("Bắt đầu lại", radius.filters(), 10.78, 106.7, "Điểm đã chọn"));
            assertTrue(reset.clearLocation());
            assertEquals(ChatFilters.empty(), reset.filters());
            verify(listings, never()).findNearby(anyDouble(), anyDouble(), anyDouble());
        }
    }
}
