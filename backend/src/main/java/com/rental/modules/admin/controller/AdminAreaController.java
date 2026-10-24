package com.rental.modules.admin.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.admin.dto.request.AdminAreaRequest;
import com.rental.modules.admin.dto.request.AdminAreaStatusRequest;
import com.rental.modules.admin.dto.response.AdminAreaResponse;
import com.rental.modules.admin.service.AdminAreaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/areas")
@PreAuthorize("hasRole('ADMIN')")
public class AdminAreaController {
    private final AdminAreaService service;

    public AdminAreaController(AdminAreaService service) { this.service = service; }

    @GetMapping
    public ApiResponse<AdminAreaService.AreaPage> search(@RequestParam(defaultValue = "") String query,
            @RequestParam(required = false) String type, @RequestParam(required = false) Long parentId,
            @RequestParam(required = false) Boolean active, @RequestParam(defaultValue = "0") int page) {
        return ApiResponse.success("Danh sách khu vực.", service.search(query, type, parentId, active, page));
    }

    @GetMapping("/parents")
    public ApiResponse<List<AdminAreaResponse>> parents() {
        return ApiResponse.success("Đơn vị cấp trên.", service.parents());
    }

    @GetMapping("/{id}")
    public ApiResponse<AdminAreaResponse> detail(@PathVariable Long id) {
        return ApiResponse.success("Thông tin khu vực.", service.detail(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AdminAreaResponse> create(@Valid @RequestBody AdminAreaRequest request) {
        return ApiResponse.success("Đã thêm khu vực.", service.create(request));
    }

    @PutMapping("/{id}")
    public ApiResponse<AdminAreaResponse> update(@PathVariable Long id, @Valid @RequestBody AdminAreaRequest request) {
        return ApiResponse.success("Đã cập nhật khu vực.", service.update(id, request));
    }

    @PatchMapping("/{id}/status")
    public ApiResponse<AdminAreaResponse> status(@PathVariable Long id, @Valid @RequestBody AdminAreaStatusRequest request) {
        return ApiResponse.success("Đã cập nhật trạng thái khu vực.", service.changeStatus(id, request.active()));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success("Đã xóa khu vực.", null);
    }
}
