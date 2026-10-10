package com.rental.modules.user.dto.response;


public class AuthResponse {

    private String accessToken;
    private String refreshToken;
    private Long userId;
    private String role;

    public AuthResponse() {}
    public AuthResponse(String accessToken, String refreshToken, Long userId, String role) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.userId = userId;
        this.role = role;
    }
    public String getAccessToken() { return accessToken; }    public void setAccessToken(String accessToken) { this.accessToken = accessToken; }
    public String getRefreshToken() { return refreshToken; }    public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }
    public Long getUserId() { return userId; }    public void setUserId(Long userId) { this.userId = userId; }
    public String getRole() { return role; }    public void setRole(String role) { this.role = role; }

}
