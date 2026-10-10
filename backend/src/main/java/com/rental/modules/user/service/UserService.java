package com.rental.modules.user.service;

import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.entity.UserPreference;
import com.rental.modules.user.dto.request.UpdateAvatarRequest;
import com.rental.modules.user.dto.request.UpdateProfileRequest;
import com.rental.modules.user.dto.request.UserPreferenceDto;
import com.rental.modules.user.dto.response.UserProfileResponse;
import com.rental.modules.user.repository.UserPreferenceRepository;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final UserPreferenceRepository userPreferenceRepository;

    public UserService(UserRepository userRepository, UserPreferenceRepository userPreferenceRepository) {
        this.userRepository = userRepository;
        this.userPreferenceRepository = userPreferenceRepository;
    }


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

    public UserProfileResponse updateAvatar(String email, UpdateAvatarRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        user.setAvatarUrl(request.getAvatarUrl());

        User updatedUser = userRepository.save(user);

        return mapToUserProfileResponse(updatedUser);
    }

    private UserProfileResponse mapToUserProfileResponse(User user) {
        UserProfileResponse response = new UserProfileResponse();
        response.setId(user.getUserId());
        response.setFullName(user.getFullName());
        response.setEmail(user.getEmail());
        response.setPhoneNumber(user.getPhoneNumber());
        response.setAvatarUrl(user.getAvatarUrl());
        response.setRole(user.getRole() != null ? user.getRole().name() : null);
        response.setStatus(user.getStatus() != null ? user.getStatus().name() : null);
        return response;
    }

    public UserPreferenceDto getMyPreferences(String email) {
        userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        UserPreference preference = userPreferenceRepository.findByUser_Email(email).orElse(null);

        if (preference == null) {
            return new UserPreferenceDto();
        }

        UserPreferenceDto response = new UserPreferenceDto();
        response.setMinBudget(preference.getMinBudget());
        response.setMaxBudget(preference.getMaxBudget());
        response.setHasPet(preference.getHasPet());
        response.setPreferredArea(preference.getPreferredArea());
        return response;
    }

    public UserPreferenceDto updateMyPreferences(String email, UserPreferenceDto request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        UserPreference preference = userPreferenceRepository.findByUser_Email(email).orElse(null);

        if (preference == null) {
            preference = new UserPreference();
            preference.setUser(user);
        }

        preference.setMinBudget(request.getMinBudget());
        preference.setMaxBudget(request.getMaxBudget());
        preference.setHasPet(request.getHasPet());
        preference.setPreferredArea(request.getPreferredArea());

        UserPreference updatedPreference = userPreferenceRepository.save(preference);

        UserPreferenceDto response = new UserPreferenceDto();
        response.setMinBudget(updatedPreference.getMinBudget());
        response.setMaxBudget(updatedPreference.getMaxBudget());
        response.setHasPet(updatedPreference.getHasPet());
        response.setPreferredArea(updatedPreference.getPreferredArea());
        return response;
    }
}
