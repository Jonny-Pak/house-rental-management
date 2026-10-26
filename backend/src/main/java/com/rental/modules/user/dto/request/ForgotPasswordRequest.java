package com.rental.modules.user.dto.request;
import jakarta.validation.constraints.*;
public record ForgotPasswordRequest(@NotBlank @Email @Size(max = 150) String email) {}
