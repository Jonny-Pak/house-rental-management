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
import org.springframework.transaction.annotation.Transactional;
import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.subscription.repository.UserSubscriptionRepository;
import org.springframework.util.StringUtils;

@Service
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final UserPreferenceRepository userPreferenceRepository;

    private final UserSubscriptionRepository userSubscriptionRepository;

    public UserService(UserRepository userRepository, UserPreferenceRepository userPreferenceRepository, UserSubscriptionRepository userSubscriptionRepository) {
        this.userSubscriptionRepository = userSubscriptionRepository;
        this.userRepository = userRepository;
        this.userPreferenceRepository = userPreferenceRepository;
    }

    public UserProfileResponse getMyProfile(String email) {
        java.util.Optional<User> userResult = userRepository.findByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("User not found with email: " + email);
        }
        User user = userResult.get();

        return mapToUserProfileResponse(user);
    }

    public UserProfileResponse updateMyProfile(String email, UpdateProfileRequest request) {
        java.util.Optional<User> userResult = userRepository.findByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("User not found with email: " + email);
        }
        User user = userResult.get();

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
        java.util.Optional<User> userResult = userRepository.findByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("User not found with email: " + email);
        }
        User user = userResult.get();

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
        if (user.getRole() != null) {
            response.setRole(user.getRole().name());
        }
        if (user.getStatus() != null) {
            response.setStatus(user.getStatus().name());
        }
        UserSubscription subscription = userSubscriptionRepository.findByUser(user).orElse(null);
        if (subscription != null) {
            response.setSubscriptionStatus(subscription.getStatus());
            if (subscription.getMembershipPackage() != null) {
                response.setMembershipPackageName(subscription.getMembershipPackage().getPackageName());
            }
            response.setRemainingStandardQuota(subscription.getRemainingStandardQuota());
            response.setRemainingVipQuota(subscription.getRemainingVipQuota());
            response.setRemainingRefreshQuota(subscription.getRemainingRefreshQuota());
        }
        UserPreference preference = userPreferenceRepository.findByUser_Email(user.getEmail()).orElse(null);
        if (preference != null) response.setInterests(new java.util.ArrayList<>(preference.getInterests()));
        return response;
    }

    public UserPreferenceDto getMyPreferences(String email) {
        if (userRepository.findByEmail(email).isEmpty()) {
            throw new IllegalArgumentException("User not found with email: " + email);
        }

        UserPreference preference = userPreferenceRepository.findByUser_Email(email).orElse(null);

        if (preference == null) {
            UserPreferenceDto empty = new UserPreferenceDto();
            empty.setInterests(java.util.List.of());
            return empty;
        }

        UserPreferenceDto response = new UserPreferenceDto();
        response.setInterests(new java.util.ArrayList<>(preference.getInterests()));
        response.setMinBudget(preference.getMinBudget());
        response.setMaxBudget(preference.getMaxBudget());
        response.setHasPet(preference.getHasPet());
        response.setPreferredArea(preference.getPreferredArea());
        return response;
    }

    public UserPreferenceDto updateMyPreferences(String email, UserPreferenceDto request) {
        java.util.Optional<User> userResult = userRepository.findByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("User not found with email: " + email);
        }
        User user = userResult.get();

        UserPreference preference = userPreferenceRepository.findByUser_Email(email).orElse(null);

        if (preference == null) {
            preference = new UserPreference();
            preference.setUser(user);
        }

        if (request.getInterests() != null) {
            preference.setInterests(new java.util.ArrayList<>(new java.util.LinkedHashSet<>(request.getInterests())));
        }
        preference.setMinBudget(request.getMinBudget());
        preference.setMaxBudget(request.getMaxBudget());
        preference.setHasPet(request.getHasPet());
        preference.setPreferredArea(request.getPreferredArea());

        UserPreference updatedPreference = userPreferenceRepository.save(preference);

        UserPreferenceDto response = new UserPreferenceDto();
        response.setInterests(new java.util.ArrayList<>(updatedPreference.getInterests()));
        response.setMinBudget(updatedPreference.getMinBudget());
        response.setMaxBudget(updatedPreference.getMaxBudget());
        response.setHasPet(updatedPreference.getHasPet());
        response.setPreferredArea(updatedPreference.getPreferredArea());
        return response;
    }
}
