package com.rental.modules.subscription.domain.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "dang_ky_goi_dich_vu")
public class UserSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_dang_ky_goi")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_nguoi_dung", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_goi_dich_vu", nullable = false)
    private MembershipPackage membershipPackage;

    @Column(name = "thoi_diem_mua_goi", updatable = false)
    private LocalDateTime purchasedAt = LocalDateTime.now();

    @Column(name = "luot_tin_thuong_con_lai")
    private Integer remainingStandardQuota;

    @Column(name = "luot_tin_uu_tien_con_lai")
    private Integer remainingVipQuota;

    @Column(name = "luot_lam_moi_con_lai")
    private Integer remainingRefreshQuota;

    @Column(name = "moc_dat_lai_han_muc")
    private LocalDateTime quotaResetAt;

    @Column(name = "trang_thai", nullable = false, length = 10)
    private String status = "ACTIVE";

    @Column(name = "ten_goi_tai_thoi_diem_mua", length = 20)
    private String packageNameSnapshot;
    public String getPackageNameSnapshot() { return packageNameSnapshot; }
    public void setPackageNameSnapshot(String value) { packageNameSnapshot = value; }

    public UserSubscription() {}

    public UserSubscription(User user, MembershipPackage membershipPackage, LocalDateTime purchasedAt, Short remainingStandardQuota, Short remainingVipQuota, Short remainingRefreshQuota, LocalDateTime quotaResetAt, String status) {
        this.user = user;
        this.membershipPackage = membershipPackage;
        if (purchasedAt != null) this.purchasedAt = purchasedAt;
        this.remainingStandardQuota = remainingStandardQuota == null ? null : remainingStandardQuota.intValue();
        this.remainingVipQuota = remainingVipQuota == null ? null : remainingVipQuota.intValue();
        this.remainingRefreshQuota = remainingRefreshQuota == null ? null : remainingRefreshQuota.intValue();
        this.quotaResetAt = quotaResetAt;
        if (status != null) this.status = status;
    }

    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }
    public void setUser(User user) {
        this.user = user;
    }

    public MembershipPackage getMembershipPackage() {
        return membershipPackage;
    }
    public void setMembershipPackage(MembershipPackage membershipPackage) {
        this.membershipPackage = membershipPackage;
    }

    public LocalDateTime getPurchasedAt() {
        return purchasedAt;
    }
    public void setPurchasedAt(LocalDateTime purchasedAt) {
        this.purchasedAt = purchasedAt;
    }

    public Integer getRemainingStandardQuota() {
        return remainingStandardQuota;
    }
    public void setRemainingStandardQuota(Integer remainingStandardQuota) {
        this.remainingStandardQuota = remainingStandardQuota;
    }

    public Integer getRemainingVipQuota() {
        return remainingVipQuota;
    }
    public void setRemainingVipQuota(Integer remainingVipQuota) {
        this.remainingVipQuota = remainingVipQuota;
    }

    public Integer getRemainingRefreshQuota() {
        return remainingRefreshQuota;
    }
    public void setRemainingRefreshQuota(Integer remainingRefreshQuota) {
        this.remainingRefreshQuota = remainingRefreshQuota;
    }

    public LocalDateTime getQuotaResetAt() {
        return quotaResetAt;
    }
    public void setQuotaResetAt(LocalDateTime quotaResetAt) {
        this.quotaResetAt = quotaResetAt;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }
}

