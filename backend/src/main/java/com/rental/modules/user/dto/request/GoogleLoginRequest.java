package com.rental.modules.user.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleLoginRequest {

    @NotBlank(message = "ID Token không được để trống")
    private String idToken;
}
