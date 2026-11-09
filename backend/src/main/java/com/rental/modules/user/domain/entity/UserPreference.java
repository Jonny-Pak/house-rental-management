package com.rental.modules.user.domain.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "so_thich_nguoi_dung")
public class UserPreference {
    @ElementCollection
    @CollectionTable(name = "so_thich_da_chon", joinColumns = @JoinColumn(name = "ma_ho_so_so_thich"))
    @Column(name = "ma_so_thich", nullable = false, length = 32)
    private java.util.List<String> interests = new java.util.ArrayList<>();

    public java.util.List<String> getInterests() { return interests; }
    public void setInterests(java.util.List<String> interests) { this.interests = new java.util.ArrayList<>(interests); }


    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_ho_so_so_thich")
    private Long preferenceId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_nguoi_dung", nullable = false, unique = true)
    private User user;

    @Column(name = "ngan_sach_toi_thieu")
    private Double minBudget;

    @Column(name = "ngan_sach_toi_da")
    private Double maxBudget;

    @Column(name = "co_thu_cung")
    private Boolean hasPet;

    @Column(name = "khu_vuc_mong_muon", length = 150)
    private String preferredArea;

    public UserPreference() {}

    public UserPreference(Long preferenceId, User user, Double minBudget, Double maxBudget, Boolean hasPet, String preferredArea) {
        this.preferenceId = preferenceId;
        this.user = user;
        this.minBudget = minBudget;
        this.maxBudget = maxBudget;
        this.hasPet = hasPet;
        this.preferredArea = preferredArea;
    }

    public Long getPreferenceId() {
        return preferenceId;
    }
    public void setPreferenceId(Long preferenceId) {
        this.preferenceId = preferenceId;
    }

    public User getUser() {
        return user;
    }
    public void setUser(User user) {
        this.user = user;
    }

    public Double getMinBudget() {
        return minBudget;
    }
    public void setMinBudget(Double minBudget) {
        this.minBudget = minBudget;
    }

    public Double getMaxBudget() {
        return maxBudget;
    }
    public void setMaxBudget(Double maxBudget) {
        this.maxBudget = maxBudget;
    }

    public Boolean getHasPet() {
        return hasPet;
    }
    public void setHasPet(Boolean hasPet) {
        this.hasPet = hasPet;
    }

    public String getPreferredArea() {
        return preferredArea;
    }
    public void setPreferredArea(String preferredArea) {
        this.preferredArea = preferredArea;
    }
}
