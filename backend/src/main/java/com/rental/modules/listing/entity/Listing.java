package com.rental.modules.listing.entity;

import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.locationtech.jts.geom.Point;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
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

    @Column(name = "approval_status", nullable = false, length = 15)
    @Builder.Default
    private String approvalStatus = "PENDING";

    @Column(name = "rental_status", nullable = false, length = 15)
    @Builder.Default
    private String rentalStatus = "AVAILABLE";

    @Column(name = "rejection_reason", length = 255)
    private String rejectionReason;

    @Column(name = "is_vip")
    @Builder.Default
    private Boolean isVip = false;

    @Column(name = "vip_expires_at")
    private LocalDateTime vipExpiresAt;

    @Column(name = "refreshed_at")
    private LocalDateTime refreshedAt;

    @Column(name = "view_count")
    @Builder.Default
    private Integer viewCount = 0;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}