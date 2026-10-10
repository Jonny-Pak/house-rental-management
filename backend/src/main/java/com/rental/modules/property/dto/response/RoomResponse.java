package com.rental.modules.property.dto.response;


import java.math.BigDecimal;

public class RoomResponse {
    private Long id;
    private Long propertyId;
    private String name;
    private Double area;
    private BigDecimal price;
    private Integer maxCapacity;
    private String status;

    public RoomResponse() {}
    public RoomResponse(Long id, Long propertyId, String name, Double area, BigDecimal price, Integer maxCapacity, String status) {
        this.id = id;
        this.propertyId = propertyId;
        this.name = name;
        this.area = area;
        this.price = price;
        this.maxCapacity = maxCapacity;
        this.status = status;
    }
    public Long getId() { return id; }    public void setId(Long id) { this.id = id; }
    public Long getPropertyId() { return propertyId; }    public void setPropertyId(Long propertyId) { this.propertyId = propertyId; }
    public String getName() { return name; }    public void setName(String name) { this.name = name; }
    public Double getArea() { return area; }    public void setArea(Double area) { this.area = area; }
    public BigDecimal getPrice() { return price; }    public void setPrice(BigDecimal price) { this.price = price; }
    public Integer getMaxCapacity() { return maxCapacity; }    public void setMaxCapacity(Integer maxCapacity) { this.maxCapacity = maxCapacity; }
    public String getStatus() { return status; }    public void setStatus(String status) { this.status = status; }

}
