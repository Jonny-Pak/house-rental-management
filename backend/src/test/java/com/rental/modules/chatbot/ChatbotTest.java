package com.rental.modules.chatbot;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rental.modules.amenity.dto.AmenityResponse;
import com.rental.modules.amenity.service.AmenityService;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.service.ListingService;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ChatbotTest {
    ObjectMapper json = new ObjectMapper();
    ListingService listings = mock(ListingService.class);
    ChatbotSearch search = new ChatbotSearch(listings);
    ChatbotAiClient ai = mock(ChatbotAiClient.class);
    AmenityService amenities = mock(AmenityService.class);
    ChatbotService service = new ChatbotService(ai, search, amenities);

    ChatFilters filters(String fields) throws Exception { return json.readValue("{" + fields + "}", ChatFilters.class); }

    @Test void resetClearsConditionsAndLocationWithoutSearching() throws Exception {
        when(ai.analyze(any(),any())).thenReturn(new SearchPlan("RESET","NONE",ChatFilters.empty()));
        var old = filters("\"maxPrice\":4000000,\"radiusKm\":3");
        var reply = service.reply(1L,new ChatRequest("Bắt đầu lại",old,10.78,106.7,"Điểm cũ"));
        assertTrue(reply.clearLocation());
        assertEquals(ChatFilters.empty(), reply.filters());
        verifyNoInteractions(listings);
    }

    ListingResponse listing(long id, String approval, String status, long price) {
        var item = new ListingResponse();
        item.setId(id); item.setTitle("Phòng sạch sẽ Thủ Đức"); item.setAddress("Phường Linh Xuân, TP Hồ Chí Minh");
        item.setDescription("Yên tĩnh, không hút thuốc"); item.setListingType("BOARDING_ROOM");
        item.setApprovalStatus(approval); item.setRentalStatus(status); item.setRentPrice(BigDecimal.valueOf(price));
        item.setAreaSqm(BigDecimal.valueOf(30)); item.setAllowPets(true); item.setAllowSmoking(false);
        item.setBedrooms(2); item.setGenderPreference("ANY");
        item.setAmenities(List.of(new AmenityResponse(1L,"Máy lạnh","UTILITY","",true,0L,0L)));
        return item;
    }

    @Test void strictFiltersMatchVietnameseWithoutAccentsAndNeverReturnPrivateOrUnavailableListings() throws Exception {
        ChatFilters f = filters("\"listingType\":\"BOARDING_ROOM\",\"maxPrice\":4000000,\"locationText\":\"Thu Duc\",\"allowPets\":true,\"allowSmoking\":false,\"amenities\":[\"May lanh\"],\"keywords\":[\"yen tinh\"],\"bedrooms\":2,\"genderPreference\":\"FEMALE\"");
        assertTrue(search.matches(listing(1,"APPROVED","AVAILABLE",3000000), f));
        for (String status : List.of("HIDDEN","RENTED","DELETED")) assertFalse(search.matches(listing(2,"APPROVED",status,3000000), f));
        assertFalse(search.matches(listing(3,"PENDING","AVAILABLE",3000000), f));
        assertFalse(search.matches(listing(4,"APPROVED","AVAILABLE",5000000), f));
        var unknownPets = listing(5,"APPROVED","AVAILABLE",3000000); unknownPets.setAllowPets(null);
        assertFalse(search.matches(unknownPets, f));
        assertFalse(search.matches(listing(6,"APPROVED","AVAILABLE",3000000), filters("\"amenities\":[\"Hồ bơi\"]")));
        assertFalse(search.matches(listing(7,"APPROVED","AVAILABLE",3000000), filters("\"keywords\":[\"thang máy\"]")));
    }

    @Test void searchUsesExistingSpatialQueryAndSortsPricesWithoutChangingFilters() throws Exception {
        var f = filters("\"radiusKm\":3,\"maxPrice\":4000000,\"sort\":\"PRICE_ASC\"");
        when(listings.findNearby(10.78,106.7,3)).thenReturn(List.of(listing(1,"APPROVED","AVAILABLE",3500000),listing(2,"APPROVED","AVAILABLE",2500000)));
        var result = search.find(f,10.78,106.7);
        assertEquals(2L, result.getFirst().getId());
        verify(listings).findNearby(10.78,106.7,3);
        verify(listings,never()).getApprovedListings();
    }

    @Test void asksForLocationBeforeRadiusSearchAndReusesChosenPointOnFollowup() throws Exception {
        var f = filters("\"radiusKm\":3,\"maxPrice\":4000000");
        when(ai.analyze(any(),any())).thenReturn(new SearchPlan("SEARCH","LOCATION",f));
        var first = service.reply(1L,new ChatRequest("Quanh đây 3 km",ChatFilters.empty(),null,null,null));
        assertTrue(first.locationRequired()); assertEquals(0,first.total()); verifyNoInteractions(listings);
        when(listings.findNearby(10.78,106.7,3)).thenReturn(List.of(listing(1,"APPROVED","AVAILABLE",3000000)));
        var next = service.reply(1L,new ChatRequest("Đã chọn điểm",f,10.78,106.7,"Điểm đã chọn"));
        assertFalse(next.locationRequired()); assertEquals(1,next.total());
    }

    @Test void changingNamedCenterRequiresNewConfirmationRatherThanUsingOldPoint() throws Exception {
        var previous = filters("\"radiusKm\":3,\"locationText\":\"Thủ Đức\"");
        var changed = filters("\"radiusKm\":3,\"locationText\":\"Bình Thạnh\"");
        when(ai.analyze(any(),any())).thenReturn(new SearchPlan("SEARCH","NONE",changed));
        assertTrue(service.reply(1L,new ChatRequest("Đổi sang Bình Thạnh",previous,10.78,106.7,"Thủ Đức")).locationRequired());
        verifyNoInteractions(listings);
    }

    @Test void zeroMatchesDoNotRelaxConditionsOrInventListings() throws Exception {
        var f = filters("\"maxPrice\":1000000,\"amenities\":[\"Hồ bơi\"]");
        when(ai.analyze(any(),any())).thenReturn(new SearchPlan("SEARCH","NONE",f));
        when(listings.getApprovedListings()).thenReturn(List.of(listing(1,"APPROVED","AVAILABLE",3000000)));
        var reply = service.reply(1L,new ChatRequest("Tìm phòng",ChatFilters.empty(),null,null,null));
        assertEquals(0,reply.total()); assertTrue(reply.listings().isEmpty()); assertEquals(f,reply.filters());
    }

    @Test void resultCountIsRealButOnlyFiveCardsAreReturned() {
        when(ai.analyze(any(),any())).thenReturn(new SearchPlan("SEARCH","NONE",ChatFilters.empty()));
        var rows = new java.util.ArrayList<ListingResponse>();
        for (long id=1;id<=8;id++) rows.add(listing(id,"APPROVED","AVAILABLE",3000000));
        when(listings.getApprovedListings()).thenReturn(rows);
        var reply = service.reply(1L,new ChatRequest("Tất cả phòng",ChatFilters.empty(),null,null,null));
        assertEquals(8,reply.total()); assertEquals(5,reply.listings().size());
    }

    @Test void helpAndUnsupportedActionsDoNotSearchOrChangeContext() throws Exception {
        var previous = filters("\"maxPrice\":4000000");
        for (String action : List.of("HELP","UNSUPPORTED")) {
            when(ai.analyze(any(),any())).thenReturn(new SearchPlan(action,"NONE",ChatFilters.empty()));
            assertEquals(previous,service.reply(1L,new ChatRequest("Xin chào",previous,null,null,null)).filters());
        }
        verifyNoInteractions(listings);
    }

    @Test void invalidRangesAndRequestFloodAreRejectedBeforeCallingAi() throws Exception {
        assertThrows(ResponseStatusException.class,()->service.reply(1L,new ChatRequest("Tìm",filters("\"minPrice\":5,\"maxPrice\":1"),null,null,null)));
        verifyNoInteractions(ai);
        when(ai.analyze(any(),any())).thenReturn(new SearchPlan("HELP","NONE",ChatFilters.empty()));
        for(int i=0;i<12;i++) service.reply(2L,new ChatRequest("Chào",null,null,null,null));
        assertEquals(429,assertThrows(ResponseStatusException.class,()->service.reply(2L,new ChatRequest("Chào",null,null,null,null))).getStatusCode().value());
        verifyNoInteractions(ai);
    }
}
