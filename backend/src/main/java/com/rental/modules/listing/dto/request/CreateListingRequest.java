package com.rental.modules.listing.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.*;
import java.util.List;

import java.math.BigDecimal;

public class CreateListingRequest {
    @Min(0) @Max(20)
    private Integer currentOccupants;
    @Min(1) @Max(20)
    private Integer maxOccupants;
    @Pattern(regexp = "ANY|MALE|FEMALE")
    private String genderPreference;
    private Boolean allowPets;
    private Boolean allowSmoking;
    @Size(max = 500)
    private String roommateRequirements;

    @NotBlank(message = "Title is required")
    @Size(max = 200)
    private String title;

    @Size(max = 10000)
    private String description;

    @NotBlank(message = "Listing type is required")
    @Pattern(regexp = "WHOLE_HOUSE|BOARDING_ROOM|SHARED_ROOM")
    private String listingType;

    @NotNull(message = "Rent price is required")
    @DecimalMin("0.01") @Digits(integer = 10, fraction = 2)
    private BigDecimal rentPrice;

    @NotNull @DecimalMin("0.01") @Digits(integer = 4, fraction = 2)
    private BigDecimal areaSqm;

    @NotBlank(message = "Address is required")
    @Size(max = 255)
    private String address;

    @NotNull(message = "Area ID is required")
    private Long areaId;

    @NotNull(message = "Latitude is required")
    @DecimalMin("-90") @DecimalMax("90")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin("-180") @DecimalMax("180")
    private Double longitude;

    @Size(max = 50)
    private String houseType;
    @Min(0) @Max(100)
    private Integer bedrooms;
    @Min(0) @Max(100)
    private Integer bathrooms;
    @Min(0) @Max(100)
    private Integer totalFloors;
    @Size(max = 50)
    private String doorDirection;
    @Size(max = 100)
    private String legalDocuments;
    @Size(max = 50)
    private String furnitureStatus;
    @DecimalMin("0") @Digits(integer = 10, fraction = 2)
    private BigDecimal depositAmount;
    @Size(max = 20)
    private String posterType;

    @NotEmpty @Size(max = 10)
    private List<@NotBlank @Size(max = 255) @Pattern(regexp = "https://[^\\s]+", message = "Image URL must use HTTPS") String> imageUrls;
    public List<String> getImageUrls() {
        return imageUrls;
    }
    public void setImageUrls(List<String> imageUrls) {
        this.imageUrls = imageUrls;
    }

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
    public Long getAreaId() {
        return areaId;
    }

    public void setAreaId(Long areaId) {
        this.areaId = areaId;
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
    @AssertTrue(message = "Tin ở ghép cần số người hợp lệ, còn chỗ trống và giới tính ưu tiên.")
    public boolean isSharedRoomValid() {
        if (!"SHARED_ROOM".equals(listingType)) return true;
        return currentOccupants != null && maxOccupants != null
                && currentOccupants >= 0 && maxOccupants <= 20
                && maxOccupants > currentOccupants
                && java.util.List.of("ANY", "MALE", "FEMALE").contains(genderPreference == null ? "" : genderPreference);
    }
}

