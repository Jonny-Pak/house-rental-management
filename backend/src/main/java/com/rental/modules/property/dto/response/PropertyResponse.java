package com.rental.modules.property.dto.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class PropertyResponse {
    private Long id;
    private Long landlordId;
    private String name;
    private String description;
    private String address;
    private Long provinceId;
    private Long districtId;
    private Long wardId;
    private BigDecimal electricityPrice;
    private BigDecimal waterPrice;
    private String propertyType;
    private String status;
    private String landlordPhone;
    private List<String> imageUrls;
}
