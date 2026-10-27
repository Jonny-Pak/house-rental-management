package com.rental.modules.subscription.domain.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_subscriptions")
public class UserSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "subscription_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "package_id", nullable = false)
    private MembershipPackage membershipPackage;

    @Column(name = "purchased_at", updatable = false)
    private LocalDateTime purchasedAt = LocalDateTime.now();

    @Column(name = "remaining_standard_quota")
    private Integer remainingStandardQuota;

    @Column(name = "remaining_vip_quota")
    private Integer remainingVipQuota;

    @Column(name = "remaining_refresh_quota")
    private Integer remainingRefreshQuota;

    @Column(name = "quota_reset_at")
    private LocalDateTime quotaResetAt;

    @Column(nullable = false, length = 10)
    private String status = "ACTIVE";

    @Column(name = "package_name_snapshot", length = 20)
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

