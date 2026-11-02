package com.rental.modules.amenity.domain.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "amenities")
public class Amenity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "amenity_id") private Long id;
    @Column(nullable = false, length = 100) private String name;
    @Column(nullable = false, length = 20) private String category;
    @Column(nullable = false, length = 255) private String description = "";
    @Column(nullable = false) private boolean active = true;
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
