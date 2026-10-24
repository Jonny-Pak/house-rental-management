package com.rental.modules.admin.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class AdminListingResponse {
    private Integer currentOccupants;
    private Integer maxOccupants;
    private String genderPreference;
    private Boolean allowPets;
    private Boolean allowSmoking;
    private String roommateRequirements;
    private java.util.List<String> imageUrls;
    public java.util.List<String> getImageUrls() {
        return imageUrls;
    }
    public void setImageUrls(java.util.List<String> urls) {
        imageUrls = urls;
    }

    private Long id;
    private String title;
    private String description;
    private String listingType;
    private BigDecimal rentPrice;
    private BigDecimal areaSqm;
    private String address;
    private Double latitude;
    private Double longitude;

    private Long ownerId;
    private String ownerName;
    private String ownerEmail;
    private String ownerPhone;

    private Long areaId;
    private String areaName;

    private String approvalStatus;
    private String rentalStatus;
    private String rejectionReason;

    private Long approvedById;
    private String approvedByName;

    private String houseType;
    private Integer bedrooms;
    private Integer bathrooms;
    private Integer totalFloors;
    private String doorDirection;
    private String legalDocuments;
    private String furnitureStatus;
    private BigDecimal depositAmount;
    private String posterType;

    private Boolean isVip;
    private Integer viewCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }
    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    public String getListingType() {
        return listingType;
    }
    public void setListingType(String listingType) {
        this.listingType = listingType;
    }
    public BigDecimal getRentPrice() {
        return rentPrice;
    }
    public void setRentPrice(BigDecimal rentPrice) {
        this.rentPrice = rentPrice;
    }
    public BigDecimal getAreaSqm() {
        return areaSqm;
    }
    public void setAreaSqm(BigDecimal areaSqm) {
        this.areaSqm = areaSqm;
    }
    public String getAddress() {
        return address;
    }
    public void setAddress(String address) {
        this.address = address;
    }
    public Double getLatitude() {
        return latitude;
    }
    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }
    public Double getLongitude() {
        return longitude;
    }
    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }
    public Long getOwnerId() {
        return ownerId;
    }
    public void setOwnerId(Long ownerId) {
        this.ownerId = ownerId;
    }
    public String getOwnerName() {
        return ownerName;
    }
    public void setOwnerName(String ownerName) {
        this.ownerName = ownerName;
    }
    public String getOwnerEmail() {
        return ownerEmail;
    }
    public void setOwnerEmail(String ownerEmail) {
        this.ownerEmail = ownerEmail;
    }
    public String getOwnerPhone() {
        return ownerPhone;
    }
    public void setOwnerPhone(String ownerPhone) {
        this.ownerPhone = ownerPhone;
    }
    public Long getAreaId() {
        return areaId;
    }
    public void setAreaId(Long areaId) {
        this.areaId = areaId;
    }
    public String getAreaName() {
        return areaName;
    }
    public void setAreaName(String areaName) {
        this.areaName = areaName;
    }
    public String getApprovalStatus() {
        return approvalStatus;
    }
    public void setApprovalStatus(String approvalStatus) {
        this.approvalStatus = approvalStatus;
    }
    public String getRentalStatus() {
        return rentalStatus;
    }
    public void setRentalStatus(String rentalStatus) {
        this.rentalStatus = rentalStatus;
    }
    public String getRejectionReason() {
        return rejectionReason;
    }
    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }
    public Long getApprovedById() {
        return approvedById;
    }
    public void setApprovedById(Long approvedById) {
        this.approvedById = approvedById;
    }
    public String getApprovedByName() {
        return approvedByName;
    }
    public void setApprovedByName(String approvedByName) {
        this.approvedByName = approvedByName;
    }
    public String getHouseType() {
        return houseType;
    }
    public void setHouseType(String houseType) {
        this.houseType = houseType;
    }
    public Integer getBedrooms() {
        return bedrooms;
    }
    public void setBedrooms(Integer bedrooms) {
        this.bedrooms = bedrooms;
    }
    public Integer getBathrooms() {
        return bathrooms;
    }
    public void setBathrooms(Integer bathrooms) {
        this.bathrooms = bathrooms;
    }
    public Integer getTotalFloors() {
        return totalFloors;
    }
    public void setTotalFloors(Integer totalFloors) {
        this.totalFloors = totalFloors;
    }
    public String getDoorDirection() {
        return doorDirection;
    }
    public void setDoorDirection(String doorDirection) {
        this.doorDirection = doorDirection;
    }
    public String getLegalDocuments() {
        return legalDocuments;
    }
    public void setLegalDocuments(String legalDocuments) {
        this.legalDocuments = legalDocuments;
    }
    public String getFurnitureStatus() {
        return furnitureStatus;
    }
    public void setFurnitureStatus(String furnitureStatus) {
        this.furnitureStatus = furnitureStatus;
    }
    public BigDecimal getDepositAmount() {
        return depositAmount;
    }
    public void setDepositAmount(BigDecimal depositAmount) {
        this.depositAmount = depositAmount;
    }
    public String getPosterType() {
        return posterType;
    }
    public void setPosterType(String posterType) {
        this.posterType = posterType;
    }
    public Boolean getIsVip() {
        return isVip;
    }
    public void setIsVip(Boolean isVip) {
        this.isVip = isVip;
    }
    public Integer getViewCount() {
        return viewCount;
    }
    public void setViewCount(Integer viewCount) {
        this.viewCount = viewCount;
    }
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public AdminListingResponse() {}
    public Integer getCurrentOccupants() { return currentOccupants; }
    public void setCurrentOccupants(Integer currentOccupants) { this.currentOccupants = currentOccupants; }
    public Integer getMaxOccupants() { return maxOccupants; }
    public void setMaxOccupants(Integer maxOccupants) { this.maxOccupants = maxOccupants; }
    public String getGenderPreference() { return genderPreference; }
    public void setGenderPreference(String genderPreference) { this.genderPreference = genderPreference; }
    public Boolean getAllowPets() { return allowPets; }
    public void setAllowPets(Boolean allowPets) { this.allowPets = allowPets; }
    public Boolean getAllowSmoking() { return allowSmoking; }
    public void setAllowSmoking(Boolean allowSmoking) { this.allowSmoking = allowSmoking; }
    public String getRoommateRequirements() { return roommateRequirements; }
    public void setRoommateRequirements(String roommateRequirements) { this.roommateRequirements = roommateRequirements; }
}

