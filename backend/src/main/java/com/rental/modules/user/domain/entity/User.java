package com.rental.modules.user.domain.entity;

import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "nguoi_dung")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_nguoi_dung")
    private Long userId;

    @Column(name = "ho_va_ten", length = 150, nullable = false)
    private String fullName;

    @Column(name = "dia_chi_thu_dien_tu", length = 150, unique = true, nullable = false)
    private String email;

    @Column(name = "so_dien_thoai", length = 15, unique = true)
    private String phoneNumber;

    @Column(name = "mat_khau_da_bam")
    private String passwordHash;

    @Column(name = "ma_tai_khoan_google", length = 100, unique = true)
    private String googleId;

    @Column(name = "duong_dan_anh_dai_dien")
    private String avatarUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "vai_tro", nullable = false, length = 10)
    private Role role;

    @Enumerated(EnumType.STRING)
    @Column(name = "trang_thai", nullable = false, length = 10)
    private UserStatus status;

    @Column(name = "da_xac_thuc_thu_dien_tu")
    private Boolean isVerified;

    @CreationTimestamp
    @Column(name = "thoi_diem_tao", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "thoi_diem_cap_nhat")
    private LocalDateTime updatedAt;

    @Column(name = "phien_ban_mat_khau", nullable = false)
    private int passwordVersion = 0;

    public int getPasswordVersion() { return passwordVersion; }
    public void setPasswordVersion(int value) { passwordVersion = value; }

    public Long getUserId() {
        return userId;
    }
    public void setUserId(Long userId) {
        this.userId = userId;
    }
    public String getFullName() {
        return fullName;
    }
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }
    public String getPhoneNumber() {
        return phoneNumber;
    }
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
    public String getPasswordHash() {
        return passwordHash;
    }
    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }
    public String getGoogleId() {
        return googleId;
    }
    public void setGoogleId(String googleId) {
        this.googleId = googleId;
    }
    public String getAvatarUrl() {
        return avatarUrl;
    }
    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }
    public Role getRole() {
        return role;
    }
    public void setRole(Role role) {
        this.role = role;
    }
    public UserStatus getStatus() {
        return status;
    }
    public void setStatus(UserStatus status) {
        this.status = status;
    }
    public Boolean getIsVerified() {
        return isVerified;
    }
    public void setIsVerified(Boolean isVerified) {
        this.isVerified = isVerified;
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
