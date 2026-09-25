package com.rental.modules.listing.controller;

import com.rental.modules.listing.dto.response.MapListingResponse;
import com.rental.modules.listing.service.ListingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/listings")
@RequiredArgsConstructor
public class ListingController {

    private final ListingService listingService;

    /**
     * GET /api/v1/listings/map?minLat=10.7&minLng=106.6&maxLat=10.9&maxLng=106.8
     *
     * Trả về các Listing nằm trong vùng hiển thị trên bản đồ (bounding box).
     * Flutter gọi API này mỗi khi người dùng pan/zoom bản đồ.
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
}
