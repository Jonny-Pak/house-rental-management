package com.rental.modules.amenity.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.amenity.dto.*;
import com.rental.modules.amenity.service.AmenityService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/amenities")
@PreAuthorize("hasRole('ADMIN')")
public class AdminAmenityController {
    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public org.springframework.http.ResponseEntity<ApiResponse<Void>> conflict() {
        return org.springframework.http.ResponseEntity.status(409).body(ApiResponse.error("Tên đã tồn tại hoặc danh mục đã có dữ liệu liên quan. Hãy tải lại danh sách."));
    }
    private final AmenityService service;
    public AdminAmenityController(AmenityService service) { this.service = service; }
    public record StatusRequest(@NotNull Boolean active, @NotNull Long version) {}
    @GetMapping public ApiResponse<AmenityService.AmenityPage> list(@RequestParam(defaultValue = "") String query, @RequestParam(required = false) String category, @RequestParam(required = false) Boolean active, @RequestParam(defaultValue = "0") int page) {
        return ApiResponse.success("Danh mục nội thất/tiện ích.", service.search(query, category, active, page));
    }
    @PostMapping public ApiResponse<AmenityResponse> create(@Valid @RequestBody SaveAmenityRequest request) { return ApiResponse.success("Đã thêm danh mục.", service.create(request)); }
    @PutMapping("/{id}") public ApiResponse<AmenityResponse> update(@PathVariable Long id, @Valid @RequestBody SaveAmenityRequest request) { return ApiResponse.success("Đã cập nhật danh mục.", service.update(id, request)); }
    @PatchMapping("/{id}/status") public ApiResponse<AmenityResponse> status(@PathVariable Long id, @Valid @RequestBody StatusRequest request) { return ApiResponse.success("Đã cập nhật trạng thái.", service.changeStatus(id, request.active(), request.version())); }
    @DeleteMapping("/{id}") public ApiResponse<String> delete(@PathVariable Long id, @RequestParam Long version) { service.delete(id, version); return ApiResponse.success("Đã xóa danh mục."); }
}
