package com.rental.modules.user.dto.request;
import jakarta.validation.constraints.*;
public record ResetPasswordRequest(@NotBlank @Email @Size(max = 150) String email, @NotBlank @Pattern(regexp = "[0-9]{6}") String otp, @NotBlank @Size(min = 8, max = 72) String newPassword) {}
