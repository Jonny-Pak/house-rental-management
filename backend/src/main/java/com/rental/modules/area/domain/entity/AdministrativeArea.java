package com.rental.modules.area.domain.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "khu_vuc_hanh_chinh")
public class AdministrativeArea {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_khu_vuc")
    private Long areaId;

    @Column(name = "ten_khu_vuc", length = 150, nullable = false)
    private String areaName;

    @Column(name = "cap_hanh_chinh", length = 10)
    private String areaType;

    @Column(name = "ma_quan_ly", length = 20)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_khu_vuc_cap_tren")
    private AdministrativeArea parent;

    @Column(name = "dang_su_dung", nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "thoi_diem_tao", updatable = false)
    private LocalDateTime createdAt;

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public boolean isAvailable() {
        AdministrativeArea current = this;
        while (current != null) {
            if (!current.isActive()) return false;
            current = current.getParent();
        }
        return true;
    }

    public Long getAreaId() {
        return areaId;
    }
    public void setAreaId(Long areaId) {
        this.areaId = areaId;
    }
    public String getAreaName() {
        return areaName;
    }
    public void setAreaName(String areaName) {
        this.areaName = areaName;
    }
    public String getAreaType() {
        return areaType;
    }
    public void setAreaType(String areaType) {
        this.areaType = areaType;
    }
    public String getCode() {
        return code;
    }
    public void setCode(String code) {
        this.code = code;
    }
    public AdministrativeArea getParent() {
        return parent;
    }
    public void setParent(AdministrativeArea parent) {
        this.parent = parent;
    }
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
