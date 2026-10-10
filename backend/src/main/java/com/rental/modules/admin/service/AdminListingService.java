package com.rental.modules.admin.service;

import com.rental.modules.admin.dto.response.AdminListingResponse;
import com.rental.modules.listing.entity.Listing;
import com.rental.modules.listing.repository.ListingRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminListingService {

    private final ListingRepository listingRepository;
    private final UserRepository userRepository;

    public AdminListingService(ListingRepository listingRepository, UserRepository userRepository) {
        this.listingRepository = listingRepository;
        this.userRepository = userRepository;
    }

    /**
     * Returns all listings with PENDING approval status for admin review.
     */
    @Transactional(readOnly = true)
    public List<AdminListingResponse> getPendingListings() {
        return listingRepository.findByApprovalStatus("PENDING")
                .stream()
                .map(this::toAdminListingResponse)
                .collect(Collectors.toList());
    }

    /**
     * Approves a listing. Sets approvalStatus = APPROVED and records who approved.
     */
    @Transactional
    public AdminListingResponse approveListing(Long listingId, Long adminId) {
        return updateApprovalStatus(listingId, adminId, "APPROVED", null);
    }

    /**
     * Rejects a listing. Sets approvalStatus = REJECTED with a reason.
     */
    @Transactional
    public AdminListingResponse rejectListing(Long listingId, Long adminId, String reason) {
        return updateApprovalStatus(listingId, adminId, "REJECTED", reason);
    }

    private AdminListingResponse updateApprovalStatus(Long listingId, Long adminId, String status, String reason) {
        Listing listing = listingRepository.findById(listingId)
                .orElseThrow(() -> new IllegalArgumentException("Listing not found with id: " + listingId));

        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Admin user not found with id: " + adminId));

        listing.setApprovalStatus(status);
        listing.setApprovedBy(admin);
        listing.setRejectionReason(reason);
        listing.setUpdatedAt(LocalDateTime.now());

        Listing saved = listingRepository.save(listing);
        return toAdminListingResponse(saved);
    }

    private AdminListingResponse toAdminListingResponse(Listing listing) {
        AdminListingResponse response = new AdminListingResponse();
        response.setId(listing.getId());
        response.setTitle(listing.getTitle());
        response.setDescription(listing.getDescription());
        response.setListingType(listing.getListingType());
        response.setRentPrice(listing.getRentPrice());
        response.setAreaSqm(listing.getAreaSqm());
        response.setAddress(listing.getAddress());
        response.setLatitude(listing.getLocation() != null ? listing.getLocation().getY() : null);
        response.setLongitude(listing.getLocation() != null ? listing.getLocation().getX() : null);
        response.setOwnerId(listing.getOwner().getUserId());
        response.setOwnerName(listing.getOwner().getFullName());
        response.setOwnerEmail(listing.getOwner().getEmail());
        response.setOwnerPhone(listing.getOwner().getPhoneNumber());
        response.setAreaId(listing.getArea().getAreaId());
        response.setAreaName(listing.getArea().getAreaName());
        response.setApprovalStatus(listing.getApprovalStatus());
        response.setRentalStatus(listing.getRentalStatus());
        response.setRejectionReason(listing.getRejectionReason());
        response.setApprovedById(listing.getApprovedBy() != null ? listing.getApprovedBy().getUserId() : null);
        response.setApprovedByName(listing.getApprovedBy() != null ? listing.getApprovedBy().getFullName() : null);
        response.setHouseType(listing.getHouseType());
        response.setBedrooms(listing.getBedrooms());
        response.setBathrooms(listing.getBathrooms());
        response.setTotalFloors(listing.getTotalFloors());
        response.setDoorDirection(listing.getDoorDirection());
        response.setLegalDocuments(listing.getLegalDocuments());
        response.setFurnitureStatus(listing.getFurnitureStatus());
        response.setDepositAmount(listing.getDepositAmount());
        response.setPosterType(listing.getPosterType());
        response.setCreatedAt(listing.getCreatedAt());
        response.setUpdatedAt(listing.getUpdatedAt());
        return response;
    }
}

