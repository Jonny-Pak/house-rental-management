package com.rental.modules.property.domain.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "properties")
public class Property {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "landlord_id", nullable = false)
    private User landlord;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private String address;

    @Column(name = "province_id", nullable = false)
    private Long provinceId;

    @Column(name = "district_id", nullable = false)
    private Long districtId;

    @Column(name = "ward_id", nullable = false)
    private Long wardId;

    @Column(name = "electricity_price")
    private BigDecimal electricityPrice;

    @Column(name = "water_price")
    private BigDecimal waterPrice;

    @Column(name = "property_type", length = 50)
    private String propertyType;

    @Column(length = 50)
    private String status;

    @OneToMany(mappedBy = "property", cascade = CascadeType.ALL, orphanRemoval = true)
    private java.util.List<Room> rooms;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = "ACTIVE";
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public Property() {}
    public Property(Long id, User landlord, String name, String description, String address, Long provinceId, Long districtId, Long wardId, BigDecimal electricityPrice, BigDecimal waterPrice, String propertyType, String status, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.landlord = landlord;
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
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
    public Long getId() { return id; }    public void setId(Long id) { this.id = id; }
    public User getLandlord() { return landlord; }    public void setLandlord(User landlord) { this.landlord = landlord; }
    public String getName() { return name; }    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }    public void setDescription(String description) { this.description = description; }
    public String getAddress() { return address; }    public void setAddress(String address) { this.address = address; }
    public Long getProvinceId() { return provinceId; }    public void setProvinceId(Long provinceId) { this.provinceId = provinceId; }
    public Long getDistrictId() { return districtId; }    public void setDistrictId(Long districtId) { this.districtId = districtId; }
    public Long getWardId() { return wardId; }    public void setWardId(Long wardId) { this.wardId = wardId; }
    public BigDecimal getElectricityPrice() { return electricityPrice; }    public void setElectricityPrice(BigDecimal electricityPrice) { this.electricityPrice = electricityPrice; }
    public BigDecimal getWaterPrice() { return waterPrice; }    public void setWaterPrice(BigDecimal waterPrice) { this.waterPrice = waterPrice; }
    public String getPropertyType() { return propertyType; }    public void setPropertyType(String propertyType) { this.propertyType = propertyType; }
    public String getStatus() { return status; }    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

}
