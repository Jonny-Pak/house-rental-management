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

    @GetMapping("/public/{id}")
    public ListingResponse getPublicListing(@PathVariable Long id) {
        return listingService.getPublicListing(id);
    }

    @GetMapping("/me")
    public List<ListingResponse> getMyListings(@AuthenticationPrincipal com.rental.core.security.CustomUserDetails user) {
        return listingService.getMyListings(user.getUser().getUserId());
    }

    @PutMapping("/{id}")
    public ListingResponse updateListing(@PathVariable Long id,
            @AuthenticationPrincipal com.rental.core.security.CustomUserDetails user,
            @Valid @RequestBody CreateListingRequest request) {
        return listingService.updateListing(id, user.getUser().getUserId(), request);
    }

    @PatchMapping("/{id}/rental-status")
    public ListingResponse updateRentalStatus(@PathVariable Long id,
            @AuthenticationPrincipal com.rental.core.security.CustomUserDetails user,
            @Valid @RequestBody com.rental.modules.listing.dto.request.UpdateRentalStatusRequest request) {
        return listingService.updateRentalStatus(id, user.getUser().getUserId(), request.getRentalStatus());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteListing(@PathVariable Long id,
            @AuthenticationPrincipal com.rental.core.security.CustomUserDetails user) {
        listingService.deleteListing(id, user.getUser().getUserId());
        return ResponseEntity.noContent().build();
    }

    private final ListingService listingService;

    public ListingController(ListingService listingService) {
        this.listingService = listingService;
    }

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

    @GetMapping("/public")
    public ResponseEntity<List<ListingResponse>> getPublicListings() {
        List<ListingResponse> listings = listingService.getApprovedListings();
        return ResponseEntity.ok(listings);
    }

    @PostMapping
    public ResponseEntity<ListingResponse> createListing(
            @AuthenticationPrincipal com.rental.core.security.CustomUserDetails userDetails,
            @Valid @RequestBody CreateListingRequest request) {

        ListingResponse response = listingService.createListing(userDetails.getUser().getUserId(), request);
        return ResponseEntity.status(201).body(response);
    }
}
