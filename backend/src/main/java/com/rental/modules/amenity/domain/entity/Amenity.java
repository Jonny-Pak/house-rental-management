package com.rental.modules.amenity.domain.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "danh_muc_tien_ich")
public class Amenity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_tien_ich") private Long id;
    @Column(name = "ten_hien_thi", nullable = false, length = 100) private String name;
    @Column(name = "nhom_phan_loai", nullable = false, length = 20) private String category;
    @Column(name = "mo_ta", nullable = false, length = 255) private String description = "";
    @Column(name = "dang_su_dung", nullable = false) private boolean active = true;
    @Column(name = "phien_ban_du_lieu")
    @Version private Long version;

    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String value) { name = value; }
    public String getCategory() { return category; }
    public void setCategory(String value) { category = value; }
    public String getDescription() { return description; }
    public void setDescription(String value) { description = value; }
    public boolean isActive() { return active; }
    public void setActive(boolean value) { active = value; }
    public Long getVersion() { return version; }
}
