package com.rental.modules.incident.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.core.security.CustomUserDetails;
import com.rental.modules.incident.dto.*;
import com.rental.modules.incident.service.IncidentService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/incidents")
@PreAuthorize("hasRole('ADMIN')")
public class AdminIncidentController {
    private final IncidentService service;
    public AdminIncidentController(IncidentService service) { this.service = service; }
    @GetMapping
    public ApiResponse<IncidentPage> list(@RequestParam(defaultValue = "") String query,
        @RequestParam(required = false) String status, @RequestParam(required = false) String category,
        @RequestParam(defaultValue = "0") int page) {
        return ApiResponse.success("Danh sách báo cáo sự cố.", service.search(null, query, status, category, page));
    }
    @GetMapping("/{id}")
    public ApiResponse<IncidentResponse> detail(@PathVariable Long id) {
        return ApiResponse.success("Chi tiết báo cáo.", service.detail(id, null));
    }
    @PatchMapping("/{id}")
    public ApiResponse<IncidentResponse> update(@AuthenticationPrincipal CustomUserDetails user, @PathVariable Long id, @Valid @RequestBody UpdateIncidentRequest request) {
        return ApiResponse.success("Đã cập nhật xử lý báo cáo.", service.update(id, user.getUser().getUserId(), request));
    }
}
