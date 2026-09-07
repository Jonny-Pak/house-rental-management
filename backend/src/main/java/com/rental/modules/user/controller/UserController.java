package com.rental.modules.user.controller;

import com.rental.modules.user.dto.request.UpdateProfileRequest;
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
        return ResponseEntity.ok(ApiResponse.success("Truy vấn hồ sơ người dùng thành công.", profileResponse));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateMyProfile(
            Principal principal,
            @RequestBody UpdateProfileRequest request) {
        String email = principal.getName();
        UserProfileResponse profileResponse = userService.updateMyProfile(email, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật hồ sơ người dùng thành công.", profileResponse));
    }
}
