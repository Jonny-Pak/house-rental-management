package com.rental.modules.content.domain.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "noi_dung_he_thong")
public class SystemContent {
    @Id
    @Column(name = "ma_duong_dan_trang", length = 20)
    private String slug;
    @Column(name = "tieu_de", nullable = false, length = 150)
    private String title;
    @Column(name = "noi_dung_ban_nhap", nullable = false, columnDefinition = "TEXT")
    private String body;
    @Column(name = "tieu_de_cong_khai", length = 150)
    private String publishedTitle;
    @Column(name = "noi_dung_cong_khai", columnDefinition = "TEXT")
    private String publishedBody;
    @Column(name = "da_xuat_ban", nullable = false)
    private boolean published;
    @Column(name = "thoi_diem_xuat_ban")
    private LocalDateTime publishedAt;
    @UpdateTimestamp
    @Column(name = "thoi_diem_cap_nhat", nullable = false)
    private LocalDateTime updatedAt;
    @Column(name = "phien_ban_du_lieu")
    @Version
    private Long version;

    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }
    public String getPublishedTitle() { return publishedTitle; }
    public void setPublishedTitle(String title) { this.publishedTitle = title; }
    public String getPublishedBody() { return publishedBody; }
    public void setPublishedBody(String body) { this.publishedBody = body; }
    public boolean isPublished() { return published; }
    public void setPublished(boolean published) { this.published = published; }
    public LocalDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(LocalDateTime date) { this.publishedAt = date; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getVersion() { return version; }
}
