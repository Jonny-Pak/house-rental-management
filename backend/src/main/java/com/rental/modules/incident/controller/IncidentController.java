package com.rental.modules.incident.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.core.security.CustomUserDetails;
import com.rental.modules.incident.dto.*;
import com.rental.modules.incident.service.IncidentService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/api/v1/incidents")
public class IncidentController {
    private final IncidentService service;
    public IncidentController(IncidentService service) { this.service = service; }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<IncidentResponse> create(@AuthenticationPrincipal CustomUserDetails user, @Valid @RequestBody CreateIncidentRequest request) {
        return ApiResponse.success("Đã tiếp nhận báo cáo sự cố.", service.create(user.getUser().getUserId(), request));
    }
    @GetMapping("/me")
    public ApiResponse<IncidentPage> mine(@AuthenticationPrincipal CustomUserDetails user,
        @RequestParam(defaultValue = "") String query, @RequestParam(required = false) String status,
        @RequestParam(required = false) String category, @RequestParam(defaultValue = "0") int page) {
        return ApiResponse.success("Báo cáo của tôi.", service.search(user.getUser().getUserId(), query, status, category, page));
    }
    @GetMapping("/{id}")
    public ApiResponse<IncidentResponse> detail(@AuthenticationPrincipal CustomUserDetails user, @PathVariable Long id) {
        return ApiResponse.success("Chi tiết báo cáo.", service.detail(id, user.getUser().getUserId()));
    }
}
