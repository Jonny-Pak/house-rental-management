package com.rental.modules.listing.entity;

import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import org.locationtech.jts.geom.Point;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "listings")
public class Listing {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "listing_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "area_id", nullable = false)
    private AdministrativeArea area;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private User approvedBy;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "listing_type", nullable = false, length = 15)
    private String listingType;

    @Column(name = "rent_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal rentPrice;

    @Column(name = "area_sqm", precision = 6, scale = 2)
    private BigDecimal areaSqm;

    @Column(length = 255)
    private String address;

    @Column(columnDefinition = "geometry(Point,4326)")
    private Point location;

    @Column(name = "house_type", length = 50)
    private String houseType;

    @Column(name = "bedrooms")
    private Integer bedrooms;

    @Column(name = "bathrooms")
    private Integer bathrooms;

    @Column(name = "total_floors")
    private Integer totalFloors;

    @Column(name = "door_direction", length = 50)
    private String doorDirection;

    @Column(name = "legal_documents", length = 100)
    private String legalDocuments;

    @Column(name = "furniture_status", length = 50)
    private String furnitureStatus;

    @Column(name = "deposit_amount", precision = 12, scale = 2)
    private BigDecimal depositAmount;

    @Column(name = "poster_type", length = 20)
    private String posterType;

    @Column(name = "approval_status", nullable = false, length = 15)
    private String approvalStatus = "PENDING";

    @Column(name = "rental_status", nullable = false, length = 15)
    private String rentalStatus = "AVAILABLE";

    @Column(name = "rejection_reason", length = 255)
    private String rejectionReason;

    @Column(name = "is_vip")
    private Boolean isVip = false;

    @Column(name = "vip_expires_at")
    private LocalDateTime vipExpiresAt;

    @Column(name = "refreshed_at")
    private LocalDateTime refreshedAt;

    @Column(name = "view_count")
    private Integer viewCount = 0;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public User getOwner() { return owner; }
    public void setOwner(User owner) { this.owner = owner; }
    public AdministrativeArea getArea() { return area; }
    public void setArea(AdministrativeArea area) { this.area = area; }
    public User getApprovedBy() { return approvedBy; }
    public void setApprovedBy(User approvedBy) { this.approvedBy = approvedBy; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getListingType() { return listingType; }
    public void setListingType(String listingType) { this.listingType = listingType; }
    public BigDecimal getRentPrice() { return rentPrice; }
    public void setRentPrice(BigDecimal rentPrice) { this.rentPrice = rentPrice; }
    public BigDecimal getAreaSqm() { return areaSqm; }
    public void setAreaSqm(BigDecimal areaSqm) { this.areaSqm = areaSqm; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public Point getLocation() { return location; }
    public void setLocation(Point location) { this.location = location; }
    public String getHouseType() { return houseType; }
    public void setHouseType(String houseType) { this.houseType = houseType; }
    public Integer getBedrooms() { return bedrooms; }
    public void setBedrooms(Integer bedrooms) { this.bedrooms = bedrooms; }
    public Integer getBathrooms() { return bathrooms; }
    public void setBathrooms(Integer bathrooms) { this.bathrooms = bathrooms; }
    public Integer getTotalFloors() { return totalFloors; }
    public void setTotalFloors(Integer totalFloors) { this.totalFloors = totalFloors; }
    public String getDoorDirection() { return doorDirection; }
    public void setDoorDirection(String doorDirection) { this.doorDirection = doorDirection; }
    public String getLegalDocuments() { return legalDocuments; }
    public void setLegalDocuments(String legalDocuments) { this.legalDocuments = legalDocuments; }
    public String getFurnitureStatus() { return furnitureStatus; }
    public void setFurnitureStatus(String furnitureStatus) { this.furnitureStatus = furnitureStatus; }
    public BigDecimal getDepositAmount() { return depositAmount; }
    public void setDepositAmount(BigDecimal depositAmount) { this.depositAmount = depositAmount; }
    public String getPosterType() { return posterType; }
    public void setPosterType(String posterType) { this.posterType = posterType; }
    public String getApprovalStatus() { return approvalStatus; }
    public void setApprovalStatus(String approvalStatus) { this.approvalStatus = approvalStatus; }
    public String getRentalStatus() { return rentalStatus; }
    public void setRentalStatus(String rentalStatus) { this.rentalStatus = rentalStatus; }
    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
    public Boolean getIsVip() { return isVip; }
    public void setIsVip(Boolean isVip) { this.isVip = isVip; }
    public LocalDateTime getVipExpiresAt() { return vipExpiresAt; }
    public void setVipExpiresAt(LocalDateTime vipExpiresAt) { this.vipExpiresAt = vipExpiresAt; }
    public LocalDateTime getRefreshedAt() { return refreshedAt; }
    public void setRefreshedAt(LocalDateTime refreshedAt) { this.refreshedAt = refreshedAt; }
    public Integer getViewCount() { return viewCount; }
    public void setViewCount(Integer viewCount) { this.viewCount = viewCount; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
