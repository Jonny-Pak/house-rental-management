package com.rental.modules.user.domain.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "user_preferences")
public class UserPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "preference_id")
    private Long preferenceId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "min_budget")
    private Double minBudget;

    @Column(name = "max_budget")
    private Double maxBudget;

    @Column(name = "has_pet")
    private Boolean hasPet;

    @Column(name = "preferred_area", length = 150)
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

    public Long getPreferenceId() { return preferenceId; }
    public void setPreferenceId(Long preferenceId) { this.preferenceId = preferenceId; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Double getMinBudget() { return minBudget; }
    public void setMinBudget(Double minBudget) { this.minBudget = minBudget; }

    public Double getMaxBudget() { return maxBudget; }
    public void setMaxBudget(Double maxBudget) { this.maxBudget = maxBudget; }

    public Boolean getHasPet() { return hasPet; }
    public void setHasPet(Boolean hasPet) { this.hasPet = hasPet; }

    public String getPreferredArea() { return preferredArea; }
    public void setPreferredArea(String preferredArea) { this.preferredArea = preferredArea; }
}
