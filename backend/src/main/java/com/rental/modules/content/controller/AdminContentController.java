package com.rental.modules.content.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.content.dto.*;
import com.rental.modules.content.service.SystemContentService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/content")
@PreAuthorize("hasRole('ADMIN')")
public class AdminContentController {
    private final SystemContentService service;
    public AdminContentController(SystemContentService service) { this.service = service; }

    @GetMapping
    public ApiResponse<List<AdminContentResponse>> list() {
        return ApiResponse.success("Danh sách nội dung hệ thống.", service.list());
    }

    @GetMapping("/{slug}")
    public ApiResponse<AdminContentResponse> detail(@PathVariable String slug) {
        return ApiResponse.success("Nội dung soạn thảo.", service.detail(slug));
    }

    @PutMapping("/{slug}")
    public ApiResponse<AdminContentResponse> save(@PathVariable String slug, @Valid @RequestBody ContentRequest request) {
        return ApiResponse.success("Đã lưu bản nháp.", service.saveDraft(slug, request));
    }

    @PostMapping("/{slug}/publish")
    public ApiResponse<AdminContentResponse> publish(@PathVariable String slug, @Valid @RequestBody ContentRequest request) {
        return ApiResponse.success("Đã xuất bản nội dung.", service.publish(slug, request));
    }

    @PostMapping("/{slug}/unpublish")
    public ApiResponse<AdminContentResponse> unpublish(@PathVariable String slug, @Valid @RequestBody ContentVersionRequest request) {
        return ApiResponse.success("Đã gỡ xuất bản. Bản soạn thảo vẫn được giữ lại.", service.unpublish(slug, request.version()));
    }
}
