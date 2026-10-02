package com.rental.modules.listing.dto.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
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
}

