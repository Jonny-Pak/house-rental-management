package com.rental.modules.user.dto.request;


public class UserPreferenceDto {
    private Double minBudget;
    private Double maxBudget;
    private Boolean hasPet;
    private String preferredArea;

    public UserPreferenceDto() {}

    public UserPreferenceDto(Double minBudget, Double maxBudget, Boolean hasPet, String preferredArea) {
        this.minBudget = minBudget;
        this.maxBudget = maxBudget;
        this.hasPet = hasPet;
        this.preferredArea = preferredArea;
    }

    public Double getMinBudget() { return minBudget; }
    public void setMinBudget(Double minBudget) { this.minBudget = minBudget; }

    public Double getMaxBudget() { return maxBudget; }
    public void setMaxBudget(Double maxBudget) { this.maxBudget = maxBudget; }

    public Boolean getHasPet() { return hasPet; }
    public void setHasPet(Boolean hasPet) { this.hasPet = hasPet; }

    public String getPreferredArea() { return preferredArea; }
    public void setPreferredArea(String preferredArea) { this.preferredArea = preferredArea; }
}
