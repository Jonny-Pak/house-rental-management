package com.rental.modules.listing.controller;

import com.rental.modules.listing.dto.response.MapListingResponse;
import com.rental.modules.listing.service.ListingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import com.rental.modules.listing.dto.request.CreateListingRequest;
import com.rental.modules.listing.dto.response.ListingResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/listings")
public class ListingController {

    private final ListingService listingService;

    public ListingController(ListingService listingService) {
        this.listingService = listingService;
    }

    /**
     * GET /api/v1/listings/map?minLat=10.7&minLng=106.6&maxLat=10.9&maxLng=106.8
     *
     * Tráº£ vá» cÃ¡c Listing náº±m trong vÃ¹ng hiá»ƒn thá»‹ trÃªn báº£n Ä‘á»“ (bounding box).
     * Flutter gá»i API nÃ y má»—i khi ngÆ°á»i dÃ¹ng pan/zoom báº£n Ä‘á»“.
     */
    @GetMapping("/map")
    public ResponseEntity<List<MapListingResponse>> getListingsOnMap(
            @RequestParam double minLat,
            @RequestParam double minLng,
            @RequestParam double maxLat,
            @RequestParam double maxLng) {

        List<MapListingResponse> results = listingService.searchListingsInBoundingBox(
                minLat, minLng, maxLat, maxLng);

        return ResponseEntity.ok(results);
    }
    @PostMapping
    public ResponseEntity<ListingResponse> createListing(
            @AuthenticationPrincipal com.rental.core.security.CustomUserDetails userDetails,
            @Valid @RequestBody CreateListingRequest request) {
        
        ListingResponse response = listingService.createListing(userDetails.getUser().getUserId(), request);
        return ResponseEntity.status(201).body(response);
    }
}
