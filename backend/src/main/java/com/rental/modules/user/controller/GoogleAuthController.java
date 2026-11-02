package com.rental.modules.user.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.user.dto.request.GoogleLoginRequest;
import com.rental.modules.user.dto.response.AuthResponse;
import com.rental.modules.user.service.GoogleAuthService;
import jakarta.validation.Valid;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class GoogleAuthController {
    private final GoogleAuthService googleAuth;

    public GoogleAuthController(GoogleAuthService googleAuth) {
        this.googleAuth = googleAuth;
    }

    @PostMapping("/api/v1/auth/google-login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody GoogleLoginRequest request) {
        try {
            AuthResponse response = googleAuth.login(request.getIdToken());
            return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                    .body(ApiResponse.success("Đăng nhập Google thành công.", response));
        } catch (DataIntegrityViolationException exception) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Tài khoản vừa được cập nhật. Vui lòng đăng nhập Google lại.");
        }
    }
}
