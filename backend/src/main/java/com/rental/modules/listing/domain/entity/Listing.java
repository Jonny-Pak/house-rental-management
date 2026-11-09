package com.rental.modules.listing.domain.entity;

import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import org.locationtech.jts.geom.Point;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "tin_cho_thue")
public class Listing {
    @ManyToMany
    @JoinTable(name = "tien_ich_cua_tin_dang", joinColumns = @JoinColumn(name = "ma_tin_dang"), inverseJoinColumns = @JoinColumn(name = "ma_tien_ich"))
    @OrderBy("category ASC, name ASC")
    private List<com.rental.modules.amenity.domain.entity.Amenity> amenities = new ArrayList<>();
    public List<com.rental.modules.amenity.domain.entity.Amenity> getAmenities() { return amenities; }

    @Column(name = "so_nguoi_dang_o")
    private Integer currentOccupants;
    @Column(name = "so_nguoi_o_toi_da")
    private Integer maxOccupants;
    @Column(name = "yeu_cau_gioi_tinh_nguoi_o")
    private String genderPreference;
    @Column(name = "cho_phep_nuoi_thu_cung")
    private Boolean allowPets;
    @Column(name = "cho_phep_hut_thuoc")
    private Boolean allowSmoking;
    @Column(name = "yeu_cau_nguoi_o_ghep", length = 500)
    private String roommateRequirements;

    @OneToMany(mappedBy = "listing", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC")
    private List<ListingImage> images = new ArrayList<>();

    public List<ListingImage> getImages() {
        return images;
    }
    public void replaceImages(List<String> urls) {
        images.clear();
        for (int i = 0; i < urls.size(); i++) images.add(new ListingImage(this, urls.get(i), i));
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_tin_dang")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_chu_tin", nullable = false)
    private User owner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_khu_vuc", nullable = false)
    private AdministrativeArea area;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_nguoi_duyet")
    private User approvedBy;

    @Column(name = "tieu_de", nullable = false, length = 200)
    private String title;

    @Column(name = "mo_ta", columnDefinition = "TEXT")
    private String description;

    @Column(name = "loai_tin_dang", nullable = false, length = 15)
    private String listingType;

    @Column(name = "gia_cho_thue", nullable = false, precision = 12, scale = 2)
    private BigDecimal rentPrice;

    @Column(name = "dien_tich_met_vuong", precision = 6, scale = 2)
    private BigDecimal areaSqm;

    @Column(name = "dia_chi", length = 255)
    private String address;

    @Column(name = "toa_do_vi_tri", columnDefinition = "geometry(Point,4326)")
    private Point location;

    @Column(name = "loai_hinh_nha", length = 50)
    private String houseType;

    @Column(name = "so_phong_ngu")
    private Integer bedrooms;

    @Column(name = "so_phong_tam")
    private Integer bathrooms;

    @Column(name = "tong_so_tang")
    private Integer totalFloors;

    @Column(name = "huong_cua", length = 50)
    private String doorDirection;

    @Column(name = "giay_to_phap_ly", length = 100)
    private String legalDocuments;

    @Column(name = "tinh_trang_noi_that", length = 50)
    private String furnitureStatus;

    @Column(name = "tien_dat_coc", precision = 12, scale = 2)
    private BigDecimal depositAmount;

    @Column(name = "loai_nguoi_dang", length = 20)
    private String posterType;

    @Column(name = "trang_thai_kiem_duyet", nullable = false, length = 15)
    private String approvalStatus = "PENDING";

    @Column(name = "trang_thai_cho_thue", nullable = false, length = 15)
    private String rentalStatus = "AVAILABLE";

    @Column(name = "ly_do_tu_choi", length = 255)
    private String rejectionReason;

    @Column(name = "la_tin_uu_tien")
    private Boolean isVip = false;

    @Column(name = "han_tin_uu_tien")
    private LocalDateTime vipExpiresAt;

    @Column(name = "thoi_diem_lam_moi_tin")
    private LocalDateTime refreshedAt;

    @Column(name = "so_luot_xem")
    private Integer viewCount = 0;

    @Column(name = "thoi_diem_tao", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "thoi_diem_cap_nhat")
    private LocalDateTime updatedAt;

    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }
    public User getOwner() {
        return owner;
    }
    public void setOwner(User owner) {
        this.owner = owner;
    }
    public AdministrativeArea getArea() {
        return area;
    }
    public void setArea(AdministrativeArea area) {
        this.area = area;
    }
    public User getApprovedBy() {
        return approvedBy;
    }
    public void setApprovedBy(User approvedBy) {
        this.approvedBy = approvedBy;
    }
    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    public String getListingType() {
        return listingType;
    }
    public void setListingType(String listingType) {
        this.listingType = listingType;
    }
    public BigDecimal getRentPrice() {
        return rentPrice;
    }
    public void setRentPrice(BigDecimal rentPrice) {
        this.rentPrice = rentPrice;
    }
    public BigDecimal getAreaSqm() {
        return areaSqm;
    }
    public void setAreaSqm(BigDecimal areaSqm) {
        this.areaSqm = areaSqm;
    }
    public String getAddress() {
        return address;
    }
    public void setAddress(String address) {
        this.address = address;
    }
    public Point getLocation() {
        return location;
    }
    public void setLocation(Point location) {
        this.location = location;
    }
    public String getHouseType() {
        return houseType;
    }
    public void setHouseType(String houseType) {
        this.houseType = houseType;
    }
    public Integer getBedrooms() {
        return bedrooms;
    }
    public void setBedrooms(Integer bedrooms) {
        this.bedrooms = bedrooms;
    }
    public Integer getBathrooms() {
        return bathrooms;
    }
    public void setBathrooms(Integer bathrooms) {
        this.bathrooms = bathrooms;
    }
    public Integer getTotalFloors() {
        return totalFloors;
    }
    public void setTotalFloors(Integer totalFloors) {
        this.totalFloors = totalFloors;
    }
    public String getDoorDirection() {
        return doorDirection;
    }
    public void setDoorDirection(String doorDirection) {
        this.doorDirection = doorDirection;
    }
    public String getLegalDocuments() {
        return legalDocuments;
    }
    public void setLegalDocuments(String legalDocuments) {
        this.legalDocuments = legalDocuments;
    }
    public String getFurnitureStatus() {
        return furnitureStatus;
    }
    public void setFurnitureStatus(String furnitureStatus) {
        this.furnitureStatus = furnitureStatus;
    }
    public BigDecimal getDepositAmount() {
        return depositAmount;
    }
    public void setDepositAmount(BigDecimal depositAmount) {
        this.depositAmount = depositAmount;
    }
    public String getPosterType() {
        return posterType;
    }
    public void setPosterType(String posterType) {
        this.posterType = posterType;
    }
    public String getApprovalStatus() {
        return approvalStatus;
    }
    public void setApprovalStatus(String approvalStatus) {
        this.approvalStatus = approvalStatus;
    }
    public String getRentalStatus() {
        return rentalStatus;
    }
    public void setRentalStatus(String rentalStatus) {
        this.rentalStatus = rentalStatus;
    }
    public String getRejectionReason() {
        return rejectionReason;
    }
    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }
    public Boolean getIsVip() {
        return isVip;
    }
    public void setIsVip(Boolean isVip) {
        this.isVip = isVip;
    }
    public LocalDateTime getVipExpiresAt() {
        return vipExpiresAt;
    }
    public void setVipExpiresAt(LocalDateTime vipExpiresAt) {
        this.vipExpiresAt = vipExpiresAt;
    }
    public LocalDateTime getRefreshedAt() {
        return refreshedAt;
    }
    public void setRefreshedAt(LocalDateTime refreshedAt) {
        this.refreshedAt = refreshedAt;
    }
    public Integer getViewCount() {
        return viewCount;
    }
    public void setViewCount(Integer viewCount) {
        this.viewCount = viewCount;
    }
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    public Integer getCurrentOccupants() { return currentOccupants; }
    public void setCurrentOccupants(Integer currentOccupants) { this.currentOccupants = currentOccupants; }
    public Integer getMaxOccupants() { return maxOccupants; }
    public void setMaxOccupants(Integer maxOccupants) { this.maxOccupants = maxOccupants; }
    public String getGenderPreference() { return genderPreference; }
    public void setGenderPreference(String genderPreference) { this.genderPreference = genderPreference; }
    public Boolean getAllowPets() { return allowPets; }
    public void setAllowPets(Boolean allowPets) { this.allowPets = allowPets; }
    public Boolean getAllowSmoking() { return allowSmoking; }
    public void setAllowSmoking(Boolean allowSmoking) { this.allowSmoking = allowSmoking; }
    public String getRoommateRequirements() { return roommateRequirements; }
    public void setRoommateRequirements(String roommateRequirements) { this.roommateRequirements = roommateRequirements; }
}
