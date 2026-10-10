package com.rental.modules.property.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public class RoomRequest {

    @NotBlank(message = "Tên phòng không được để trống")
    private String name;

    @NotNull(message = "Diện tích không được để trống")
    @Min(value = 1, message = "Diện tích phải lớn hơn 0")
    private Double area;

    @NotNull(message = "Giá thuê không được để trống")
    @Min(value = 0, message = "Giá thuê không được âm")
    private BigDecimal price;

    @NotNull(message = "Sức chứa tối đa không được để trống")
    @Min(value = 1, message = "Sức chứa tối đa phải từ 1 trở lên")
    private Integer maxCapacity;

    public RoomRequest() {}
    public RoomRequest(String name, Double area, BigDecimal price, Integer maxCapacity) {
        this.name = name;
        this.area = area;
        this.price = price;
        this.maxCapacity = maxCapacity;
    }
    public String getName() { return name; }    public void setName(String name) { this.name = name; }
    public Double getArea() { return area; }    public void setArea(Double area) { this.area = area; }
    public BigDecimal getPrice() { return price; }    public void setPrice(BigDecimal price) { this.price = price; }
    public Integer getMaxCapacity() { return maxCapacity; }    public void setMaxCapacity(Integer maxCapacity) { this.maxCapacity = maxCapacity; }

}
