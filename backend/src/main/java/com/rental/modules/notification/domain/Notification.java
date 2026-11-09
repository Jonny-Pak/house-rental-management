package com.rental.modules.notification.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "thong_bao")
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_thong_bao") private Long id;
    @Column(name = "ma_nguoi_dung", nullable = false) private Long userId;
    @Column(name = "loai_thong_bao", nullable = false, length = 30) private String type;
    @Column(name = "tieu_de", length = 150) private String title;
    @Column(name = "noi_dung", length = 500) private String content;
    @Column(name = "ma_tin_dang") private Long listingId;
    @Column(name = "ma_hop_dong") private Long contractId;
    @Column(name = "da_doc", nullable = false) private boolean read;
    @Column(name = "thoi_diem_tao") private LocalDateTime createdAt;

    @Column(name = "ma_bao_cao_su_co") private Long incidentId;
    public Long getIncidentId() { return incidentId; }
    public void setIncidentId(Long value) { incidentId = value; }

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
