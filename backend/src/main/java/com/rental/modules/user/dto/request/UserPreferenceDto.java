package com.rental.modules.user.dto.request;

public class UserPreferenceDto {
    @jakarta.validation.constraints.Size(max = 5, message = "Bạn chỉ được chọn tối đa 5 sở thích.")
    private java.util.List<@jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Pattern(regexp = "CAT_LOVER|DOG_LOVER|PLANTS|QUIET|TIDY|STUDY|EARLY_BIRD|NIGHT_OWL|NON_SMOKER|SOCIABLE|MUSIC|MOVIES|READING|GAMING|COOKING|SPORTS|TRAVEL|COFFEE") String> interests;

    public java.util.List<String> getInterests() { return interests; }
    public void setInterests(java.util.List<String> interests) { this.interests = interests; }

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
