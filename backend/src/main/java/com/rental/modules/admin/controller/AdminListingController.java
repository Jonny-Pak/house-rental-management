package com.rental.modules.admin.controller;

import com.rental.core.security.CustomUserDetails;
import com.rental.modules.admin.dto.request.RejectListingRequest;
import com.rental.modules.admin.dto.response.AdminListingResponse;
import com.rental.modules.admin.service.AdminListingService;
import com.rental.modules.user.dto.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/listings")
@PreAuthorize("hasRole('ADMIN')")
public class AdminListingController {

    private final AdminListingService adminListingService;

    public AdminListingController(AdminListingService adminListingService) {
        this.adminListingService = adminListingService;
    }

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<AdminListingResponse>>> getPendingListings() {
        List<AdminListingResponse> listings = adminListingService.getPendingListings();
        return ResponseEntity.ok(ApiResponse.success("Danh sÃ¡ch bÃ i Ä‘Äƒng chá» duyá»‡t.", listings));
    }

    @PatchMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<AdminListingResponse>> approveListing(
            @PathVariable Long id,
            @AuthenticationPrincipal CustomUserDetails adminDetails) {
        AdminListingResponse response = adminListingService.approveListing(id, adminDetails.getUser().getUserId());
        return ResponseEntity.ok(ApiResponse.success("BÃ i Ä‘Äƒng Ä‘Ã£ Ä‘Æ°á»£c duyá»‡t thÃ nh cÃ´ng.", response));
    }

    @PatchMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<AdminListingResponse>> rejectListing(
            @PathVariable Long id,
            @Valid @RequestBody RejectListingRequest request,
            @AuthenticationPrincipal CustomUserDetails adminDetails) {
        AdminListingResponse response = adminListingService.rejectListing(id, adminDetails.getUser().getUserId(), request.getReason());
        return ResponseEntity.ok(ApiResponse.success("BÃ i Ä‘Äƒng Ä‘Ã£ bá»‹ tá»« chá»‘i.", response));
    }
}

