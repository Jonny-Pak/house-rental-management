package com.rental.modules.property.domain.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "hinh_anh_tai_san")
public class PropertyImage {

    @Column(name = "ma_ban_ghi")
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_tai_san", nullable = false)
    private Property property;

    @Column(name = "duong_dan_hinh_anh", nullable = false, length = 500)
    private String imageUrl;

    @Column(name = "thoi_diem_tao", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public PropertyImage() {}
    public PropertyImage(Long id, Property property, String imageUrl, LocalDateTime createdAt) {
        this.id = id;
        this.property = property;
        this.imageUrl = imageUrl;
        this.createdAt = createdAt;
    }
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }
    public Property getProperty() {
        return property;
    }

    public void setProperty(Property property) {
        this.property = property;
    }
    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

}
