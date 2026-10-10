package com.rental.modules.listing.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public class CreateListingRequest {

    @NotBlank(message = "Title is required")
    private String title;

    private String description;

    @NotBlank(message = "Listing type is required")
    private String listingType;

    @NotNull(message = "Rent price is required")
    private BigDecimal rentPrice;

    private BigDecimal areaSqm;

    @NotBlank(message = "Address is required")
    private String address;

    @NotNull(message = "Area ID is required")
    private Long areaId;

    @NotNull(message = "Latitude is required")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    private Double longitude;

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

    public CreateListingRequest() {}
    public CreateListingRequest(String title, String description, String listingType, BigDecimal rentPrice, BigDecimal areaSqm, String address, Long areaId, Double latitude, Double longitude, String houseType, Integer bedrooms, Integer bathrooms, Integer totalFloors, String doorDirection, String legalDocuments, String furnitureStatus, BigDecimal depositAmount, String posterType) {
        this.title = title;
        this.description = description;
        this.listingType = listingType;
        this.rentPrice = rentPrice;
        this.areaSqm = areaSqm;
        this.address = address;
        this.areaId = areaId;
        this.latitude = latitude;
        this.longitude = longitude;
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
    public String getTitle() { return title; }    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }    public void setDescription(String description) { this.description = description; }
    public String getListingType() { return listingType; }    public void setListingType(String listingType) { this.listingType = listingType; }
    public BigDecimal getRentPrice() { return rentPrice; }    public void setRentPrice(BigDecimal rentPrice) { this.rentPrice = rentPrice; }
    public BigDecimal getAreaSqm() { return areaSqm; }    public void setAreaSqm(BigDecimal areaSqm) { this.areaSqm = areaSqm; }
    public String getAddress() { return address; }    public void setAddress(String address) { this.address = address; }
    public Long getAreaId() { return areaId; }    public void setAreaId(Long areaId) { this.areaId = areaId; }
    public Double getLatitude() { return latitude; }    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }    public void setLongitude(Double longitude) { this.longitude = longitude; }
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

