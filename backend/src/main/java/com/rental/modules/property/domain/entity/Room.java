package com.rental.modules.property.domain.entity;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "rooms")
public class Room {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "property_id", nullable = false)
    private Property property;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Double area;

    @Column(nullable = false)
    private BigDecimal price;

    @Column(name = "max_capacity", nullable = false)
    private Integer maxCapacity;

    @Column(length = 50)
    private String status;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
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
    public Long getId() { return id; }    public void setId(Long id) { this.id = id; }
    public Property getProperty() { return property; }    public void setProperty(Property property) { this.property = property; }
    public String getName() { return name; }    public void setName(String name) { this.name = name; }
    public Double getArea() { return area; }    public void setArea(Double area) { this.area = area; }
    public BigDecimal getPrice() { return price; }    public void setPrice(BigDecimal price) { this.price = price; }
    public Integer getMaxCapacity() { return maxCapacity; }    public void setMaxCapacity(Integer maxCapacity) { this.maxCapacity = maxCapacity; }
    public String getStatus() { return status; }    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

}
