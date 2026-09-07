package com.rental.modules.user.service;

import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.entity.UserPreference;
import com.rental.modules.user.dto.request.UpdateProfileRequest;
import com.rental.modules.user.dto.request.UserPreferenceDto;
import com.rental.modules.user.dto.response.UserProfileResponse;
import com.rental.modules.user.repository.UserPreferenceRepository;
import com.rental.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserPreferenceRepository userPreferenceRepository;

    public UserProfileResponse getMyProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        return mapToUserProfileResponse(user);
    }

    public UserProfileResponse updateMyProfile(String email, UpdateProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        if (StringUtils.hasText(request.getFullName())) {
            user.setFullName(request.getFullName());
        }
        if (StringUtils.hasText(request.getPhoneNumber())) {
            user.setPhoneNumber(request.getPhoneNumber());
        }
        if (StringUtils.hasText(request.getAvatarUrl())) {
            user.setAvatarUrl(request.getAvatarUrl());
        }

        User updatedUser = userRepository.save(user);

        return mapToUserProfileResponse(updatedUser);
    }

    private UserProfileResponse mapToUserProfileResponse(User user) {
        return UserProfileResponse.builder()
                .id(user.getUserId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .avatarUrl(user.getAvatarUrl())
                .role(user.getRole() != null ? user.getRole().name() : null)
                .status(user.getStatus() != null ? user.getStatus().name() : null)
                .build();
    }

    public UserPreferenceDto getMyPreferences(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        UserPreference preference = userPreferenceRepository.findByUser_Email(email).orElse(null);

        if (preference == null) {
            return new UserPreferenceDto();
        }

        return UserPreferenceDto.builder()
                .minBudget(preference.getMinBudget())
                .maxBudget(preference.getMaxBudget())
                .hasPet(preference.getHasPet())
                .preferredArea(preference.getPreferredArea())
                .build();
    }

    public UserPreferenceDto updateMyPreferences(String email, UserPreferenceDto request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        UserPreference preference = userPreferenceRepository.findByUser_Email(email).orElse(null);

        if (preference == null) {
            preference = UserPreference.builder()
                    .user(user)
                    .build();
        }

        preference.setMinBudget(request.getMinBudget());
        preference.setMaxBudget(request.getMaxBudget());
        preference.setHasPet(request.getHasPet());
        preference.setPreferredArea(request.getPreferredArea());

        UserPreference updatedPreference = userPreferenceRepository.save(preference);

        return UserPreferenceDto.builder()
                .minBudget(updatedPreference.getMinBudget())
                .maxBudget(updatedPreference.getMaxBudget())
                .hasPet(updatedPreference.getHasPet())
                .preferredArea(updatedPreference.getPreferredArea())
                .build();
    }
}
