package com.rental.modules.user.dto.response;

public class UserProfileResponse {
    private java.util.List<String> interests = java.util.List.of();
    public java.util.List<String> getInterests() { return interests; }
    public void setInterests(java.util.List<String> interests) { this.interests = interests; }

    private Long id;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String avatarUrl;
    private String role;
    private String status;
    private String membershipPackageName;
    private String subscriptionStatus;
    private Short remainingStandardQuota;
    private Short remainingVipQuota;
    private Short remainingRefreshQuota;

    public UserProfileResponse() {}
    public UserProfileResponse(Long id, String fullName, String email, String phoneNumber, String avatarUrl, String role, String status) {
        this.id = id;
        this.fullName = fullName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.avatarUrl = avatarUrl;
        this.role = role;
        this.status = status;
    }
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
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
    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }
    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMembershipPackageName() { return membershipPackageName; }
    public void setMembershipPackageName(String membershipPackageName) { this.membershipPackageName = membershipPackageName; }
    public String getSubscriptionStatus() { return subscriptionStatus; }
    public void setSubscriptionStatus(String subscriptionStatus) { this.subscriptionStatus = subscriptionStatus; }
    public Short getRemainingStandardQuota() { return remainingStandardQuota; }
    public void setRemainingStandardQuota(Short remainingStandardQuota) { this.remainingStandardQuota = remainingStandardQuota; }
    public Short getRemainingVipQuota() { return remainingVipQuota; }
    public void setRemainingVipQuota(Short remainingVipQuota) { this.remainingVipQuota = remainingVipQuota; }
    public Short getRemainingRefreshQuota() { return remainingRefreshQuota; }
    public void setRemainingRefreshQuota(Short remainingRefreshQuota) { this.remainingRefreshQuota = remainingRefreshQuota; }
}
