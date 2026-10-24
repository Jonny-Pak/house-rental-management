package com.rental.modules.admin.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.core.security.CustomUserDetails;
import com.rental.modules.admin.dto.request.*;
import com.rental.modules.admin.dto.response.AdminUserResponse;
import com.rental.modules.admin.service.AdminUserService;
import com.rental.modules.user.domain.enums.*;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/users")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {
    private final AdminUserService service;
    private final com.rental.modules.admin.service.AdminCreateUserService creation;

    public AdminUserController(AdminUserService service, com.rental.modules.admin.service.AdminCreateUserService creation) {
        this.service = service;
        this.creation = creation;
    }

    @PostMapping
    @ResponseStatus(org.springframework.http.HttpStatus.CREATED)
    public ApiResponse<AdminUserResponse> create(@Valid @RequestBody AdminCreateUserRequest request) {
        return ApiResponse.success("Đã tạo người dùng và gửi OTP. Người dùng cần xác thực email trên app.", creation.create(request));
    }

    @GetMapping
    public ApiResponse<AdminUserService.UserPage> search(@RequestParam(defaultValue = "") String query,
            @RequestParam(required = false) Role role, @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) Boolean verified, @RequestParam(defaultValue = "0") int page) {
        return ApiResponse.success("Danh sách người dùng.", service.search(query, role, status, verified, page));
    }

    @GetMapping("/{id}")
    public ApiResponse<AdminUserResponse> detail(@PathVariable Long id) {
        return ApiResponse.success("Thông tin người dùng.", service.detail(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<AdminUserResponse> update(@PathVariable Long id, @Valid @RequestBody AdminUpdateUserRequest request,
            @AuthenticationPrincipal CustomUserDetails admin) {
        return ApiResponse.success("Đã cập nhật người dùng.", service.update(id, admin.getUser().getUserId(), request));
    }

    @PatchMapping("/{id}/status")
    public ApiResponse<AdminUserResponse> changeStatus(@PathVariable Long id, @Valid @RequestBody AdminUserStatusRequest request,
            @AuthenticationPrincipal CustomUserDetails admin) {
        return ApiResponse.success("Đã cập nhật trạng thái.", service.changeStatus(id, admin.getUser().getUserId(), request.status()));
    }
}
