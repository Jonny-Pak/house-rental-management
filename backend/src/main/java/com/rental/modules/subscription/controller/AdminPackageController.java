package com.rental.modules.subscription.controller;
import com.rental.core.dto.ApiResponse;
import com.rental.modules.subscription.domain.entity.MembershipPackage;
import com.rental.modules.subscription.dto.SavePackageRequest;
import com.rental.modules.subscription.service.AdminPackageService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;
@RestController
@RequestMapping("/api/v1/admin/memberships")
@PreAuthorize("hasRole('ADMIN')")
public class AdminPackageController {
    private final AdminPackageService service;
    public AdminPackageController(AdminPackageService service) { this.service = service; }
    public record StatusRequest(@NotNull Boolean active, @NotNull @Min(0) Long version) {}
    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ApiResponse<String> conflict() { return ApiResponse.error("Tên gói đã tồn tại hoặc gói đang có giao dịch. Hãy tải lại danh sách."); }
    @GetMapping public ApiResponse<AdminPackageService.PackagePage> list(@RequestParam(defaultValue = "") String query, @RequestParam(required = false) Boolean active, @RequestParam(defaultValue = "0") int page) {
        return ApiResponse.success("Danh sách gói dịch vụ.", service.list(query, active, page));
    }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<MembershipPackage> create(@Valid @RequestBody SavePackageRequest request) { return ApiResponse.success("Đã tạo gói dịch vụ.", service.create(request)); }
    @PutMapping("/{id}") public ApiResponse<MembershipPackage> update(@PathVariable Short id, @Valid @RequestBody SavePackageRequest request) { return ApiResponse.success("Đã cập nhật gói dịch vụ.", service.update(id, request)); }
    @PatchMapping("/{id}/status") public ApiResponse<MembershipPackage> status(@PathVariable Short id, @Valid @RequestBody StatusRequest request) { return ApiResponse.success("Đã cập nhật trạng thái bán.", service.changeStatus(id, request.active(), request.version())); }
    @DeleteMapping("/{id}") public ApiResponse<String> delete(@PathVariable Short id, @RequestParam(required = false) Long version) { service.delete(id, version); return ApiResponse.success("Đã xóa gói chưa sử dụng."); }
}
