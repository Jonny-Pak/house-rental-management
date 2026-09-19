package com.rental.modules.subscription.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
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
    @Builder.Default
    private BigDecimal price = BigDecimal.ZERO;

    @Column(name = "standard_post_quota", nullable = false)
    private Short standardPostQuota;

    @Column(name = "vip_post_quota", nullable = false)
    @Builder.Default
    private Short vipPostQuota = 0;

    @Column(name = "refresh_quota", nullable = false)
    @Builder.Default
    private Short refreshQuota = 0;

    @Column(length = 255)
    private String description;
}