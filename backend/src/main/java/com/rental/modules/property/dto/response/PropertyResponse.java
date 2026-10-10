package com.rental.modules.property.dto.response;


import java.math.BigDecimal;
import java.util.List;

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
    private String landlordName;
    private String landlordPhone;
    private List<String> imageUrls;

    public PropertyResponse() {}

    public PropertyResponse(Long id, Long landlordId, String name, String description, String address, Long provinceId, Long districtId, Long wardId, BigDecimal electricityPrice, BigDecimal waterPrice, String propertyType, String status, String landlordName, String landlordPhone, List<String> imageUrls) {
        this.id = id;
        this.landlordId = landlordId;
        this.name = name;
        this.description = description;
        this.address = address;
        this.provinceId = provinceId;
        this.districtId = districtId;
        this.wardId = wardId;
        this.electricityPrice = electricityPrice;
        this.waterPrice = waterPrice;
        this.propertyType = propertyType;
        this.status = status;
        this.landlordName = landlordName;
        this.landlordPhone = landlordPhone;
        this.imageUrls = imageUrls;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getLandlordId() { return landlordId; }
    public void setLandlordId(Long landlordId) { this.landlordId = landlordId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public Long getProvinceId() { return provinceId; }
    public void setProvinceId(Long provinceId) { this.provinceId = provinceId; }
    public Long getDistrictId() { return districtId; }
    public void setDistrictId(Long districtId) { this.districtId = districtId; }
    public Long getWardId() { return wardId; }
    public void setWardId(Long wardId) { this.wardId = wardId; }
    public BigDecimal getElectricityPrice() { return electricityPrice; }
    public void setElectricityPrice(BigDecimal electricityPrice) { this.electricityPrice = electricityPrice; }
    public BigDecimal getWaterPrice() { return waterPrice; }
    public void setWaterPrice(BigDecimal waterPrice) { this.waterPrice = waterPrice; }
    public String getPropertyType() { return propertyType; }
    public void setPropertyType(String propertyType) { this.propertyType = propertyType; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getLandlordName() { return landlordName; }
    public void setLandlordName(String landlordName) { this.landlordName = landlordName; }
    public String getLandlordPhone() { return landlordPhone; }
    public void setLandlordPhone(String landlordPhone) { this.landlordPhone = landlordPhone; }
    public List<String> getImageUrls() { return imageUrls; }
    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; }
}
