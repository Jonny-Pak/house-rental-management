package com.rental.modules.admin.dto.request;

import com.rental.modules.user.domain.enums.Role;
import jakarta.validation.constraints.*;

public record AdminCreateUserRequest(
    @NotBlank @Size(max = 150) String fullName,
    @NotBlank @Email @Size(max = 150) String email,
    @Pattern(regexp = "^$|[0-9+][0-9]{8,14}", message = "Số điện thoại không hợp lệ.") String phoneNumber,
    @NotBlank @Size(min = 8, max = 72) String password,
    @NotNull Role role) {}
