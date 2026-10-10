package com.rental.modules.user.dto.response;


public class UserProfileResponse {
    private Long id;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String avatarUrl;
    private String role;
    private String status;

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
    public Long getId() { return id; }    public void setId(Long id) { this.id = id; }
    public String getFullName() { return fullName; }    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getEmail() { return email; }    public void setEmail(String email) { this.email = email; }
    public String getPhoneNumber() { return phoneNumber; }    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getAvatarUrl() { return avatarUrl; }    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public String getRole() { return role; }    public void setRole(String role) { this.role = role; }
    public String getStatus() { return status; }    public void setStatus(String status) { this.status = status; }

}
