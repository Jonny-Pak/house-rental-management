package com.rental.modules.contract.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.contract.service.AdminContractService;
import com.rental.modules.contract.dto.response.ContractResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;

@RestController
@RequestMapping("/api/v1/admin/contracts")
@PreAuthorize("hasRole('ADMIN')")
public class AdminContractController {
    private final AdminContractService service;
    public AdminContractController(AdminContractService service) { this.service = service; }

    @GetMapping
    public ResponseEntity<ApiResponse<AdminContractService.ContractPage>> list(
            @RequestParam(defaultValue = "") String query,
            @RequestParam(defaultValue = "") String status,
            @RequestParam(defaultValue = "") String type,
            @RequestParam(defaultValue = "0") int page) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
            .body(ApiResponse.success("Danh sách hợp đồng.", service.search(query, status, type, page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ContractResponse>> detail(@PathVariable Long id) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
            .body(ApiResponse.success("Chi tiết hợp đồng.", service.detail(id)));
    }
}
