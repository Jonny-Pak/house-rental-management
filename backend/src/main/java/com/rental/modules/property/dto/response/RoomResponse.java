package com.rental.modules.property.dto.response;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

@Data
@Builder
public class RoomResponse {
    private Long id;
    private Long propertyId;
    private String name;
    private Double area;
    private BigDecimal price;
    private Integer maxCapacity;
    private String status;
}
