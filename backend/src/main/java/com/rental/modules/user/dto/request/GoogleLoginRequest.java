package com.rental.modules.user.dto.request;

import jakarta.validation.constraints.NotBlank;

public class GoogleLoginRequest {

    @NotBlank(message = "ID Token không được để trống")
    private String idToken;

    public GoogleLoginRequest() {}
    public GoogleLoginRequest(String idToken) {
        this.idToken = idToken;
    }
    public String getIdToken() { return idToken; }    public void setIdToken(String idToken) { this.idToken = idToken; }

}
