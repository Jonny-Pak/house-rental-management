package com.rental.modules.subscription.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
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
    @Builder.Default
    private LocalDateTime purchasedAt = LocalDateTime.now();

    @Column(name = "remaining_standard_quota")
    private Short remainingStandardQuota;

    @Column(name = "remaining_vip_quota")
    private Short remainingVipQuota;

    @Column(name = "remaining_refresh_quota")
    private Short remainingRefreshQuota;

    @Column(name = "quota_reset_at")
    private LocalDateTime quotaResetAt;

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String status = "ACTIVE";
}