package com.rental.modules.admin.dto.request;

import com.rental.modules.user.domain.enums.UserStatus;
import jakarta.validation.constraints.NotNull;

public record AdminUserStatusRequest(@NotNull UserStatus status) {}
