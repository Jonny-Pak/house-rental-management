package com.rental.modules.listing.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
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
}

