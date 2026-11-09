package com.rental.modules.admin.dto.response;

import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import java.time.LocalDateTime;

public record AdminUserResponse(Long id, String fullName, String email, String phoneNumber,
        String avatarUrl, Role role, UserStatus status, boolean verified,
        LocalDateTime createdAt, LocalDateTime updatedAt) {
    public static AdminUserResponse from(User user) {
        return new AdminUserResponse(user.getUserId(), user.getFullName(), user.getEmail(),
            user.getPhoneNumber(), user.getAvatarUrl(), user.getRole(), user.getStatus(),
            Boolean.TRUE.equals(user.getIsVerified()), user.getCreatedAt(), user.getUpdatedAt());
    }
}
