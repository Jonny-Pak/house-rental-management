package com.rental.modules.user.dto.request;

import jakarta.validation.constraints.NotBlank;

public class UpdateAvatarRequest {

    @NotBlank(message = "Avatar URL must not be blank")
    private String avatarUrl;

    public UpdateAvatarRequest() {}
    public UpdateAvatarRequest(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }
    public String getAvatarUrl() { return avatarUrl; }    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

}

