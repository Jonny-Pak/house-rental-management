package com.rental.modules.property.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;

public class PropertyRequest {

    @NotBlank(message = "Tên khu trọ không được để trống")
    private String name;

    private String description;

    @NotBlank(message = "Địa chỉ không được để trống")
    private String address;

    @NotNull(message = "Tỉnh/Thành phố không được để trống")
    private Long provinceId;

    @NotNull(message = "Quận/Huyện không được để trống")
    private Long districtId;

    @NotNull(message = "Phường/Xã không được để trống")
    private Long wardId;

    private String propertyType;

    private BigDecimal electricityPrice;
    private BigDecimal waterPrice;

    private List<String> imageUrls;

    public PropertyRequest() {}
    public PropertyRequest(String name, String description, String address, Long provinceId, Long districtId, Long wardId, String propertyType, BigDecimal electricityPrice, BigDecimal waterPrice, List<String> imageUrls) {
        this.name = name;
        this.description = description;
        this.address = address;
        this.provinceId = provinceId;
        this.districtId = districtId;
        this.wardId = wardId;
        this.propertyType = propertyType;
        this.electricityPrice = electricityPrice;
        this.waterPrice = waterPrice;
        this.imageUrls = imageUrls;
    }
    public String getName() { return name; }    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }    public void setDescription(String description) { this.description = description; }
    public String getAddress() { return address; }    public void setAddress(String address) { this.address = address; }
    public Long getProvinceId() { return provinceId; }    public void setProvinceId(Long provinceId) { this.provinceId = provinceId; }
    public Long getDistrictId() { return districtId; }    public void setDistrictId(Long districtId) { this.districtId = districtId; }
    public Long getWardId() { return wardId; }    public void setWardId(Long wardId) { this.wardId = wardId; }
    public String getPropertyType() { return propertyType; }    public void setPropertyType(String propertyType) { this.propertyType = propertyType; }
    public BigDecimal getElectricityPrice() { return electricityPrice; }    public void setElectricityPrice(BigDecimal electricityPrice) { this.electricityPrice = electricityPrice; }
    public BigDecimal getWaterPrice() { return waterPrice; }    public void setWaterPrice(BigDecimal waterPrice) { this.waterPrice = waterPrice; }
    public List<String> getImageUrls() { return imageUrls; }    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; }

}
