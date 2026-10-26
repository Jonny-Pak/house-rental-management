package com.rental.modules.user.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.user.dto.request.*;
import com.rental.modules.user.service.PasswordService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;

@RestController
public class PasswordController {
    private final PasswordService passwords;
    public PasswordController(PasswordService passwords) { this.passwords = passwords; }

    @PostMapping("/api/v1/auth/forgot-password")
    public ApiResponse<String> forgot(@Valid @RequestBody ForgotPasswordRequest request) {
        return ApiResponse.success(passwords.requestReset(request.email()));
    }
    @PostMapping("/api/v1/auth/reset-password")
    public ApiResponse<String> reset(@Valid @RequestBody ResetPasswordRequest request) {
        passwords.reset(request);
        return ApiResponse.success("Đã đặt lại mật khẩu. Vui lòng đăng nhập bằng mật khẩu mới.");
    }
    @PostMapping("/api/v1/users/me/change-password")
    public ApiResponse<String> change(Principal principal, @Valid @RequestBody ChangePasswordRequest request) {
        passwords.change(principal.getName(), request);
        return ApiResponse.success("Đã đổi mật khẩu. Vui lòng đăng nhập lại.");
    }
}
