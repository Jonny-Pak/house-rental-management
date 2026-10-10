package com.rental.modules.user.dto.request;


public class UpdateProfileRequest {
    private String fullName;
    private String phoneNumber;
    private String avatarUrl;

    public UpdateProfileRequest() {}
    public UpdateProfileRequest(String fullName, String phoneNumber, String avatarUrl) {
        this.fullName = fullName;
        this.phoneNumber = phoneNumber;
        this.avatarUrl = avatarUrl;
    }
    public String getFullName() { return fullName; }    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getPhoneNumber() { return phoneNumber; }    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getAvatarUrl() { return avatarUrl; }    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

}
