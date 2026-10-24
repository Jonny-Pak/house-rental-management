package com.rental.modules.notification.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "notification_id") private Long id;
    @Column(name = "user_id", nullable = false) private Long userId;
    @Column(name = "notification_type", nullable = false, length = 30) private String type;
    @Column(length = 150) private String title;
    @Column(length = 500) private String content;
    @Column(name = "listing_id") private Long listingId;
    @Column(name = "contract_id") private Long contractId;
    @Column(name = "is_read", nullable = false) private boolean read;
    @Column(name = "created_at") private LocalDateTime createdAt;

    public Notification() {}
    public Notification(Long userId, String type, String title, String content, Long listingId, Long contractId) {
        this.userId = userId; this.type = type; this.title = title; this.content = content;
        this.listingId = listingId; this.contractId = contractId;
        this.createdAt = LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
    }
    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getType() { return type; }
    public String getTitle() { return title; }
    public String getContent() { return content; }
    public Long getListingId() { return listingId; }
    public Long getContractId() { return contractId; }
    public boolean isRead() { return read; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
