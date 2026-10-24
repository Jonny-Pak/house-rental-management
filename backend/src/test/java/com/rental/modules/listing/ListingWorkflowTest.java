package com.rental.modules.listing;

import com.rental.modules.admin.service.AdminListingService;
import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import com.rental.modules.listing.domain.entity.Listing;
import com.rental.modules.listing.dto.request.CreateListingRequest;
import com.rental.modules.listing.repository.ListingRepository;
import com.rental.modules.listing.service.ListingService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class ListingWorkflowTest {
    private ListingRepository listings;
    private ListingService service;
    private AdminListingService admin;
    private Listing stored;

    @BeforeEach void setup() {
        listings = mock(ListingRepository.class);
        UserRepository users = mock(UserRepository.class);
        AdministrativeAreaRepository areas = mock(AdministrativeAreaRepository.class);
        User owner = new User(); owner.setUserId(1L); owner.setRole(Role.MEMBER);
        User reviewer = new User(); reviewer.setUserId(2L); reviewer.setRole(Role.ADMIN);
        AdministrativeArea ward = new AdministrativeArea(); ward.setAreaId(6L); ward.setAreaType("WARD");
        when(users.findById(1L)).thenReturn(Optional.of(owner));
        when(users.findById(2L)).thenReturn(Optional.of(reviewer));
        when(areas.findById(6L)).thenReturn(Optional.of(ward));
        when(listings.save(any())).thenAnswer(call -> {
            stored = call.getArgument(0); stored.setId(10L); return stored;
        });
        when(listings.findLockedById(10L)).thenAnswer(call -> Optional.ofNullable(stored));
        when(listings.findByApprovalStatusAndRentalStatusOrderByCreatedAtDesc("APPROVED", "AVAILABLE"))
                .thenAnswer(call -> stored != null && "APPROVED".equals(stored.getApprovalStatus())
                        && "AVAILABLE".equals(stored.getRentalStatus()) ? List.of(stored) : List.of());
        service = new ListingService(listings, users, areas, mock(com.rental.modules.contract.repository.ContractRepository.class), mock(com.rental.modules.notification.service.NotificationService.class));
        admin = new AdminListingService(listings, users, mock(com.rental.modules.notification.service.NotificationService.class));
    }

    private CreateListingRequest request() {
        CreateListingRequest r = new CreateListingRequest();
        r.setTitle("Phòng trọ Quận 1"); r.setListingType("BOARDING_ROOM");
        r.setRentPrice(new BigDecimal("3000000")); r.setAreaSqm(new BigDecimal("30"));
        r.setAddress("Quận 1, TP.HCM"); r.setAreaId(6L);
        r.setLatitude(10.78); r.setLongitude(106.7);
        r.setImageUrls(List.of("https://example.com/room.jpg"));
        return r;
    }

    @Test void pendingThenApprovedThenHiddenThenAvailableThenRentedThenDeleted() {
        var created = service.createListing(1L, request());
        assertEquals("PENDING", created.getApprovalStatus());
        assertEquals("https://example.com/room.jpg", created.getImageUrl());
        assertEquals(106.7, stored.getLocation().getX());
        assertEquals(4326, stored.getLocation().getSRID());
        assertTrue(service.getApprovedListings().isEmpty());
        admin.approveListing(10L, 2L);
        assertEquals(1, service.getApprovedListings().size());
        service.updateRentalStatus(10L, 1L, "HIDDEN");
        assertTrue(service.getApprovedListings().isEmpty());
        service.updateRentalStatus(10L, 1L, "AVAILABLE");
        assertEquals(1, service.getApprovedListings().size());
        service.updateRentalStatus(10L, 1L, "RENTED");
        assertTrue(service.getApprovedListings().isEmpty());
        service.deleteListing(10L, 1L);
        assertEquals("DELETED", stored.getRentalStatus());
        assertTrue(service.getApprovedListings().isEmpty());
        assertThrows(ResponseStatusException.class, () -> service.updateRentalStatus(10L, 1L, "AVAILABLE"));
    }

    @Test void editingApprovedContentRequiresReviewAndClearsPreviousDecision() {
        service.createListing(1L, request()); admin.approveListing(10L, 2L);
        var updated = service.updateListing(10L, 1L, request());
        assertEquals("PENDING", updated.getApprovalStatus());
        assertNull(stored.getApprovedBy()); assertNull(updated.getRejectionReason());
        assertTrue(service.getApprovedListings().isEmpty());
        assertEquals(1, stored.getImages().size());
    }

    @Test void rejectedListingShowsReasonAndCanBeResubmitted() {
        service.createListing(1L, request());
        admin.rejectListing(10L, 2L, "Thiếu thông tin");
        assertTrue(service.getApprovedListings().isEmpty());
        when(listings.findByOwner_UserIdAndRentalStatusNotOrderByCreatedAtDesc(1L, "DELETED")).thenReturn(List.of(stored));
        assertEquals("Thiếu thông tin", service.getMyListings(1L).get(0).getRejectionReason());
        service.updateListing(10L, 1L, request());
        assertEquals("PENDING", stored.getApprovalStatus()); assertNull(stored.getRejectionReason());
    }

    @Test void otherUsersCannotEditHideOrDeleteListing() {
        service.createListing(1L, request());
        for (Runnable action : List.<Runnable>of(
                () -> service.updateListing(10L, 99L, request()),
                () -> service.updateRentalStatus(10L, 99L, "HIDDEN"),
                () -> service.deleteListing(10L, 99L))) {
            var error = assertThrows(ResponseStatusException.class, action::run);
            assertEquals(HttpStatus.FORBIDDEN, error.getStatusCode());
        }
        assertEquals("AVAILABLE", stored.getRentalStatus());
    }

    @Test void repeatedModerationCannotOverwriteExistingDecision() {
        service.createListing(1L, request()); admin.approveListing(10L, 2L);
        var error = assertThrows(ResponseStatusException.class, () -> admin.rejectListing(10L, 2L, "Old review"));
        assertEquals(HttpStatus.CONFLICT, error.getStatusCode());
        assertEquals("APPROVED", stored.getApprovalStatus());
    }

    @Test void deletedPendingListingCannotBeApproved() {
        service.createListing(1L, request()); service.deleteListing(10L, 1L);
        assertThrows(ResponseStatusException.class, () -> admin.approveListing(10L, 2L));
    }

    @Test void ordinaryUserCannotModerateEvenThroughService() {
        service.createListing(1L, request());
        assertThrows(org.springframework.security.access.AccessDeniedException.class, () -> admin.approveListing(10L, 1L));
        assertEquals("PENDING", stored.getApprovalStatus());
    }
}
