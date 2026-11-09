package com.rental.modules.subscription.domain.entity;

import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(name = "goi_dich_vu")
public class MembershipPackage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_goi_dich_vu")
    private Short id;

    @Column(name = "ten_goi_dich_vu", nullable = false, length = 20)
    private String packageName;

    @Column(name = "gia", nullable = false, precision = 10, scale = 2)
    private BigDecimal price = BigDecimal.ZERO;

    @Column(name = "han_muc_tin_thuong", nullable = false)
    private Short standardPostQuota;

    @Column(name = "han_muc_tin_uu_tien", nullable = false)
    private Short vipPostQuota = 0;

    @Column(name = "han_muc_lam_moi", nullable = false)
    private Short refreshQuota = 0;

    @Column(name = "mo_ta", length = 255)
    private String description;

    @Column(name = "dang_su_dung", nullable = false)
    private boolean active = true;
    @Column(name = "la_goi_mac_dinh", nullable = false)
    private boolean defaultPackage;
    public boolean isDefaultPackage() { return defaultPackage; }
    public void setDefaultPackage(boolean value) { defaultPackage = value; }
    @Column(name = "phien_ban_du_lieu")
    @Version private Long version;
    public boolean isActive() { return active; }
    public void setActive(boolean value) { active = value; }
    public Long getVersion() { return version; }

    public MembershipPackage() {}
    public MembershipPackage(Short id, String packageName, BigDecimal price, Short standardPostQuota, Short vipPostQuota, Short refreshQuota, String description) {
        this.id = id;
        this.packageName = packageName;
        this.price = price;
        this.standardPostQuota = standardPostQuota;
        this.vipPostQuota = vipPostQuota;
        this.refreshQuota = refreshQuota;
        this.description = description;
    }
    public Short getId() {
        return id;
    }

    public void setId(Short id) {
        this.id = id;
    }
    public String getPackageName() {
        return packageName;
    }

    public void setPackageName(String packageName) {
        this.packageName = packageName;
    }
    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }
    public Short getStandardPostQuota() {
        return standardPostQuota;
    }

    public void setStandardPostQuota(Short standardPostQuota) {
        this.standardPostQuota = standardPostQuota;
    }
    public Short getVipPostQuota() {
        return vipPostQuota;
    }

    public void setVipPostQuota(Short vipPostQuota) {
        this.vipPostQuota = vipPostQuota;
    }
    public Short getRefreshQuota() {
        return refreshQuota;
    }

    public void setRefreshQuota(Short refreshQuota) {
        this.refreshQuota = refreshQuota;
    }
    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

}
