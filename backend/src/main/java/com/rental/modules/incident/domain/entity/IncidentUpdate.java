package com.rental.modules.incident.domain.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "lich_su_xu_ly_su_co")
public class IncidentUpdate {
    @Column(name = "ma_ban_ghi")
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "ma_bao_cao_su_co", nullable = false)
    private Long incidentId;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_nguoi_xu_ly", nullable = false)
    private User actor;
    @Column(name = "trang_thai", nullable = false, length = 20)
    private String status;
    @Column(name = "noi_dung_thong_diep", nullable = false, length = 2000)
    private String message;
    @Column(name = "thoi_diem_tao", nullable = false)
    private LocalDateTime createdAt;

    public IncidentUpdate() {}
    public IncidentUpdate(Long incidentId, User actor, String status, String message, LocalDateTime createdAt) {
        this.incidentId = incidentId;
        this.actor = actor;
        this.status = status;
        this.message = message;
        this.createdAt = createdAt;
    }
    public Long getId() { return id; }
    public User getActor() { return actor; }
    public String getStatus() { return status; }
    public String getMessage() { return message; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
