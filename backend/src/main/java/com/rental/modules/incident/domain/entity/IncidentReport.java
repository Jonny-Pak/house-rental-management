package com.rental.modules.incident.domain.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "bao_cao_su_co")
public class IncidentReport {
    @Column(name = "ma_ban_ghi")
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_nguoi_bao_su_co", nullable = false)
    private User reporter;
    @Column(name = "khoa_doi_chieu_yeu_cau", nullable = false, length = 80)
    private String requestKey;
    @Column(name = "tieu_de", nullable = false, length = 150)
    private String title;
    @Column(name = "nhom_phan_loai", nullable = false, length = 20)
    private String category;
    @Column(name = "mo_ta", nullable = false, length = 5000)
    private String description;
    @Column(name = "trang_thai", nullable = false, length = 20)
    private String status = "OPEN";
    @Column(name = "thoi_diem_tao", nullable = false)
    private LocalDateTime createdAt;
    @Column(name = "thoi_diem_cap_nhat", nullable = false)
    private LocalDateTime updatedAt;
    @Column(name = "phien_ban_du_lieu")
    @Version private Long version;

    public Long getId() { return id; }
    public User getReporter() { return reporter; }
    public void setReporter(User value) { reporter = value; }
    public String getRequestKey() { return requestKey; }
    public void setRequestKey(String value) { requestKey = value; }
    public String getTitle() { return title; }
    public void setTitle(String value) { title = value; }
    public String getCategory() { return category; }
    public void setCategory(String value) { category = value; }
    public String getDescription() { return description; }
    public void setDescription(String value) { description = value; }
    public String getStatus() { return status; }
    public void setStatus(String value) { status = value; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime value) { createdAt = value; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime value) { updatedAt = value; }
    public Long getVersion() { return version; }
}
