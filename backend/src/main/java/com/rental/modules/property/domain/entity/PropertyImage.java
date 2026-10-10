package com.rental.modules.property.domain.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "property_images")
public class PropertyImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "property_id", nullable = false)
    private Property property;

    @Column(name = "image_url", nullable = false, length = 500)
    private String imageUrl;

    @Column(name = "created_at", updatable = false)
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
    public Long getId() { return id; }    public void setId(Long id) { this.id = id; }
    public Property getProperty() { return property; }    public void setProperty(Property property) { this.property = property; }
    public String getImageUrl() { return imageUrl; }    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public LocalDateTime getCreatedAt() { return createdAt; }    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

}
