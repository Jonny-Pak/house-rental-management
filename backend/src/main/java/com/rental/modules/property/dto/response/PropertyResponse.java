package com.rental.modules.property.dto.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

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
    private String status;
}
