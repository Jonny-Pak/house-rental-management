package com.rental.modules.admin.service;

import com.rental.modules.admin.dto.response.AdminListingResponse;
import com.rental.modules.listing.domain.entity.Listing;
import com.rental.modules.listing.repository.ListingRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

@Service
public class AdminListingService {

    private final ListingRepository listingRepository;
    private final UserRepository userRepository;

    private final com.rental.modules.notification.service.NotificationService notifications;

    public AdminListingService(ListingRepository listingRepository, UserRepository userRepository, com.rental.modules.notification.service.NotificationService notifications) {
        this.notifications = notifications;
        this.listingRepository = listingRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<AdminListingResponse> getPendingListings() {
        List<AdminListingResponse> result = new ArrayList<>();
        List<Listing> listings = listingRepository.findByApprovalStatus("PENDING");
        for (Listing listing : listings) {
            if (!"DELETED".equals(listing.getRentalStatus())) {
                result.add(toAdminListingResponse(listing));
            }
        }
        return result;
    }

    @Transactional
    public AdminListingResponse approveListing(Long listingId, Long adminId) {
        return updateApprovalStatus(listingId, adminId, "APPROVED", null);
    }

    @Transactional
    public AdminListingResponse rejectListing(Long listingId, Long adminId, String reason) {
        return updateApprovalStatus(listingId, adminId, "REJECTED", reason);
    }

    private AdminListingResponse updateApprovalStatus(Long listingId, Long adminId, String status, String reason) {
        java.util.Optional<Listing> listingResult = listingRepository.findLockedById(listingId);
        if (listingResult.isEmpty()) {
            throw new IllegalArgumentException("Listing not found with id: " + listingId);
        }
        Listing listing = listingResult.get();

        java.util.Optional<User> adminResult = userRepository.findById(adminId);
        if (adminResult.isEmpty()) {
            throw new IllegalArgumentException("Admin user not found with id: " + adminId);
        }
        User admin = adminResult.get();

        if (admin.getRole() != com.rental.modules.user.domain.enums.Role.ADMIN) {
            throw new org.springframework.security.access.AccessDeniedException("Admin required");
        }
        if (!"PENDING".equals(listing.getApprovalStatus()) || "DELETED".equals(listing.getRentalStatus())) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT, "Tin không còn ở trạng thái chờ duyệt. Vui lòng tải lại.");
        }
        listing.setApprovalStatus(status);
        listing.setApprovedBy(admin);
        listing.setRejectionReason(reason);
        listing.setUpdatedAt(LocalDateTime.now());

        Listing saved = listingRepository.save(listing);
        String title = "APPROVED".equals(status) ? "Tin đăng đã được duyệt" : "Tin đăng bị từ chối";
        String content = saved.getTitle();
        if (reason != null && !reason.isBlank()) content += " · Lý do: " + reason;
        notifications.send(saved.getOwner().getUserId(), "LISTING_" + status, title, content, saved.getId(), null);
        return toAdminListingResponse(saved);
    }

    private AdminListingResponse toAdminListingResponse(Listing listing) {
        AdminListingResponse response = new AdminListingResponse();
        List<String> imageUrls = new ArrayList<>();
        for (com.rental.modules.listing.domain.entity.ListingImage image : listing.getImages()) {
            imageUrls.add(image.getImageUrl());
        }
        response.setImageUrls(imageUrls);
        response.setId(listing.getId());
        response.setTitle(listing.getTitle());
        response.setDescription(listing.getDescription());
        response.setListingType(listing.getListingType());
        response.setRentPrice(listing.getRentPrice());
        response.setAreaSqm(listing.getAreaSqm());
        response.setAddress(listing.getAddress());
        if (listing.getLocation() != null) {
            response.setLatitude(listing.getLocation().getY());
            response.setLongitude(listing.getLocation().getX());
        }
        response.setOwnerId(listing.getOwner().getUserId());
        response.setOwnerName(listing.getOwner().getFullName());
        response.setOwnerEmail(listing.getOwner().getEmail());
        response.setOwnerPhone(listing.getOwner().getPhoneNumber());
        response.setAreaId(listing.getArea().getAreaId());
        response.setAreaName(listing.getArea().getAreaName());
        response.setApprovalStatus(listing.getApprovalStatus());
        response.setRentalStatus(listing.getRentalStatus());
        response.setRejectionReason(listing.getRejectionReason());
        if (listing.getApprovedBy() != null) {
            response.setApprovedById(listing.getApprovedBy().getUserId());
            response.setApprovedByName(listing.getApprovedBy().getFullName());
        }
        response.setHouseType(listing.getHouseType());
        response.setBedrooms(listing.getBedrooms());
        response.setBathrooms(listing.getBathrooms());
        response.setTotalFloors(listing.getTotalFloors());
        response.setDoorDirection(listing.getDoorDirection());
        response.setLegalDocuments(listing.getLegalDocuments());
        response.setFurnitureStatus(listing.getFurnitureStatus());
        response.setDepositAmount(listing.getDepositAmount());
        response.setPosterType(listing.getPosterType());
        response.setCurrentOccupants(listing.getCurrentOccupants());
        response.setMaxOccupants(listing.getMaxOccupants());
        response.setGenderPreference(listing.getGenderPreference());
        response.setAllowPets(listing.getAllowPets());
        response.setAllowSmoking(listing.getAllowSmoking());
        response.setRoommateRequirements(listing.getRoommateRequirements());

        response.setCreatedAt(listing.getCreatedAt());
        response.setUpdatedAt(listing.getUpdatedAt());
        return response;
    }
}

