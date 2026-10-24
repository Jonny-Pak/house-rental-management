package com.rental.modules.admin.dto.request;

import com.rental.modules.user.domain.enums.Role;
import jakarta.validation.constraints.*;

public record AdminUpdateUserRequest(
    @NotBlank(message = "Vui lòng nhập họ và tên.") @Size(max = 150) String fullName,
    @Pattern(regexp = "^$|[0-9+][0-9]{8,14}", message = "Số điện thoại gồm 9–15 ký tự, có thể bắt đầu bằng +.") String phoneNumber,
    @NotNull(message = "Vui lòng chọn vai trò.") Role role) {}
