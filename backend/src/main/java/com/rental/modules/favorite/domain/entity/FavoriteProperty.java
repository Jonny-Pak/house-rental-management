package com.rental.modules.favorite.domain.entity;

import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "tai_san_yeu_thich",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "property_id"}))
public class FavoriteProperty {

    @Column(name = "ma_ban_ghi")
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_nguoi_dung", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_tai_san", nullable = false)
    private Property property;

    @Column(name = "thoi_diem_tao", updatable = false)
    private LocalDateTime createdAt;

    public FavoriteProperty() {}

    public FavoriteProperty(User user, Property property) {
        this.user = user;
        this.property = property;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }
    public User getUser() {
        return user;
    }
    public void setUser(User user) {
        this.user = user;
    }
    public Property getProperty() {
        return property;
    }
    public void setProperty(Property property) {
        this.property = property;
    }
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
