package com.rental.modules.user.controller;

import com.rental.modules.user.dto.request.UpdateProfileRequest;
import com.rental.modules.user.dto.request.UserPreferenceDto;
import com.rental.modules.user.dto.response.ApiResponse;
import com.rental.modules.user.dto.response.UserProfileResponse;
import com.rental.modules.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getMyProfile(Principal principal) {
        String email = principal.getName();
        UserProfileResponse profileResponse = userService.getMyProfile(email);
        return ResponseEntity.ok(ApiResponse.success("User profile fetched successfully.", profileResponse));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateMyProfile(
            Principal principal,
            @RequestBody UpdateProfileRequest request) {
        String email = principal.getName();
        UserProfileResponse profileResponse = userService.updateMyProfile(email, request);
        return ResponseEntity.ok(ApiResponse.success("User profile updated successfully.", profileResponse));
    }

    @GetMapping("/me/preferences")
    public ResponseEntity<ApiResponse<UserPreferenceDto>> getMyPreferences(Principal principal) {
        String email = principal.getName();
        UserPreferenceDto preferencesResponse = userService.getMyPreferences(email);
        return ResponseEntity.ok(ApiResponse.success("User preferences fetched successfully.", preferencesResponse));
    }

    @PutMapping("/me/preferences")
    public ResponseEntity<ApiResponse<UserPreferenceDto>> updateMyPreferences(
            Principal principal,
            @RequestBody UserPreferenceDto request) {
        String email = principal.getName();
        UserPreferenceDto preferencesResponse = userService.updateMyPreferences(email, request);
        return ResponseEntity.ok(ApiResponse.success("User preferences updated successfully.", preferencesResponse));
    }
}
