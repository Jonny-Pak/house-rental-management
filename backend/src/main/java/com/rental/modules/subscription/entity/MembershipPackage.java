package com.rental.modules.subscription.entity;

import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(name = "membership_packages")
public class MembershipPackage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "package_id")
    private Short id;

    @Column(name = "package_name", nullable = false, length = 20)
    private String packageName;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price = BigDecimal.ZERO;

    @Column(name = "standard_post_quota", nullable = false)
    private Short standardPostQuota;

    @Column(name = "vip_post_quota", nullable = false)
    private Short vipPostQuota = 0;

    @Column(name = "refresh_quota", nullable = false)
    private Short refreshQuota = 0;

    @Column(length = 255)
    private String description;

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
    public Short getId() { return id; }    public void setId(Short id) { this.id = id; }
    public String getPackageName() { return packageName; }    public void setPackageName(String packageName) { this.packageName = packageName; }
    public BigDecimal getPrice() { return price; }    public void setPrice(BigDecimal price) { this.price = price; }
    public Short getStandardPostQuota() { return standardPostQuota; }    public void setStandardPostQuota(Short standardPostQuota) { this.standardPostQuota = standardPostQuota; }
    public Short getVipPostQuota() { return vipPostQuota; }    public void setVipPostQuota(Short vipPostQuota) { this.vipPostQuota = vipPostQuota; }
    public Short getRefreshQuota() { return refreshQuota; }    public void setRefreshQuota(Short refreshQuota) { this.refreshQuota = refreshQuota; }
    public String getDescription() { return description; }    public void setDescription(String description) { this.description = description; }

}
