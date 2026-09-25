package com.rental.modules.listing.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MapListingResponse {
    private Long id;
    private String title;
    private String listingType;
    private BigDecimal rentPrice;
    private String address;
    private double latitude;
    private double longitude;
}
