package com.rental.modules.listing.dto.response;


import java.math.BigDecimal;
import java.time.LocalDateTime;

public class ListingResponse {
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
    private Long areaId;
    private String approvalStatus;
    private String rentalStatus;
    private Boolean isVip;
    private Integer viewCount;
    private LocalDateTime createdAt;
    
    // Advanced Details
    private String houseType;
    private Integer bedrooms;
    private Integer bathrooms;
    private Integer totalFloors;
    private String doorDirection;
    private String legalDocuments;
    private String furnitureStatus;
    private BigDecimal depositAmount;
    private String posterType;

    public ListingResponse() {}
    public ListingResponse(Long id, String title, String description, String listingType, BigDecimal rentPrice, BigDecimal areaSqm, String address, Double latitude, Double longitude, Long ownerId, Long areaId, String approvalStatus, String rentalStatus, Boolean isVip, Integer viewCount, LocalDateTime createdAt, String houseType, Integer bedrooms, Integer bathrooms, Integer totalFloors, String doorDirection, String legalDocuments, String furnitureStatus, BigDecimal depositAmount, String posterType) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.listingType = listingType;
        this.rentPrice = rentPrice;
        this.areaSqm = areaSqm;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
        this.ownerId = ownerId;
        this.areaId = areaId;
        this.approvalStatus = approvalStatus;
        this.rentalStatus = rentalStatus;
        this.isVip = isVip;
        this.viewCount = viewCount;
        this.createdAt = createdAt;
        this.houseType = houseType;
        this.bedrooms = bedrooms;
        this.bathrooms = bathrooms;
        this.totalFloors = totalFloors;
        this.doorDirection = doorDirection;
        this.legalDocuments = legalDocuments;
        this.furnitureStatus = furnitureStatus;
        this.depositAmount = depositAmount;
        this.posterType = posterType;
    }
    public Long getId() { return id; }    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }    public void setDescription(String description) { this.description = description; }
    public String getListingType() { return listingType; }    public void setListingType(String listingType) { this.listingType = listingType; }
    public BigDecimal getRentPrice() { return rentPrice; }    public void setRentPrice(BigDecimal rentPrice) { this.rentPrice = rentPrice; }
    public BigDecimal getAreaSqm() { return areaSqm; }    public void setAreaSqm(BigDecimal areaSqm) { this.areaSqm = areaSqm; }
    public String getAddress() { return address; }    public void setAddress(String address) { this.address = address; }
    public Double getLatitude() { return latitude; }    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public Long getOwnerId() { return ownerId; }    public void setOwnerId(Long ownerId) { this.ownerId = ownerId; }
    public Long getAreaId() { return areaId; }    public void setAreaId(Long areaId) { this.areaId = areaId; }
    public String getApprovalStatus() { return approvalStatus; }    public void setApprovalStatus(String approvalStatus) { this.approvalStatus = approvalStatus; }
    public String getRentalStatus() { return rentalStatus; }    public void setRentalStatus(String rentalStatus) { this.rentalStatus = rentalStatus; }
    public Boolean isIsVip() { return isVip; }    public void setIsVip(Boolean isVip) { this.isVip = isVip; }
    public Integer getViewCount() { return viewCount; }    public void setViewCount(Integer viewCount) { this.viewCount = viewCount; }
    public LocalDateTime getCreatedAt() { return createdAt; }    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public String getHouseType() { return houseType; }    public void setHouseType(String houseType) { this.houseType = houseType; }
    public Integer getBedrooms() { return bedrooms; }    public void setBedrooms(Integer bedrooms) { this.bedrooms = bedrooms; }
    public Integer getBathrooms() { return bathrooms; }    public void setBathrooms(Integer bathrooms) { this.bathrooms = bathrooms; }
    public Integer getTotalFloors() { return totalFloors; }    public void setTotalFloors(Integer totalFloors) { this.totalFloors = totalFloors; }
    public String getDoorDirection() { return doorDirection; }    public void setDoorDirection(String doorDirection) { this.doorDirection = doorDirection; }
    public String getLegalDocuments() { return legalDocuments; }    public void setLegalDocuments(String legalDocuments) { this.legalDocuments = legalDocuments; }
    public String getFurnitureStatus() { return furnitureStatus; }    public void setFurnitureStatus(String furnitureStatus) { this.furnitureStatus = furnitureStatus; }
    public BigDecimal getDepositAmount() { return depositAmount; }    public void setDepositAmount(BigDecimal depositAmount) { this.depositAmount = depositAmount; }
    public String getPosterType() { return posterType; }    public void setPosterType(String posterType) { this.posterType = posterType; }

}

