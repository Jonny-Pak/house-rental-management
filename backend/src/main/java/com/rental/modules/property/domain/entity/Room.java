package com.rental.modules.property.domain.entity;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "phong_cho_thue")
public class Room {

    @Column(name = "ma_ban_ghi")
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_tai_san", nullable = false)
    private Property property;

    @Column(name = "ten_hien_thi", nullable = false)
    private String name;

    @Column(name = "dien_tich", nullable = false)
    private Double area;

    @Column(name = "gia", nullable = false)
    private BigDecimal price;

    @Column(name = "suc_chua_toi_da", nullable = false)
    private Integer maxCapacity;

    @Column(name = "trang_thai", length = 50)
    private String status;

    @Column(name = "thoi_diem_tao", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "thoi_diem_cap_nhat")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = "AVAILABLE";
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public Room() {}
    public Room(Long id, Property property, String name, Double area, BigDecimal price, Integer maxCapacity, String status, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.property = property;
        this.name = name;
        this.area = area;
        this.price = price;
        this.maxCapacity = maxCapacity;
        this.status = status;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
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
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
    public Double getArea() {
        return area;
    }

    public void setArea(Double area) {
        this.area = area;
    }
    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }
    public Integer getMaxCapacity() {
        return maxCapacity;
    }

    public void setMaxCapacity(Integer maxCapacity) {
        this.maxCapacity = maxCapacity;
    }
    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

}
