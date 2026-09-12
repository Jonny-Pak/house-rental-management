package com.rental.modules.property.controller;

import com.rental.modules.property.dto.request.PropertyRequest;
import com.rental.modules.property.dto.response.PropertyResponse;
import com.rental.modules.property.service.PropertyService;
import com.rental.modules.user.dto.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/properties")
@RequiredArgsConstructor
public class PropertyController {

    private final PropertyService propertyService;

    @PostMapping
    public ResponseEntity<ApiResponse<PropertyResponse>> createProperty(
            Principal principal,
            @Valid @RequestBody PropertyRequest request) {
        
        PropertyResponse response = propertyService.createProperty(principal.getName(), request);
        return ResponseEntity.ok(ApiResponse.success("Tạo khu trọ thành công", response));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<List<PropertyResponse>>> getMyProperties(Principal principal) {
        List<PropertyResponse> properties = propertyService.getMyProperties(principal.getName());
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách khu trọ thành công", properties));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PropertyResponse>> getPropertyById(@PathVariable Long id) {
        PropertyResponse response = propertyService.getPropertyById(id);
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin khu trọ thành công", response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<PropertyResponse>>> getAllProperties() {
        List<PropertyResponse> properties = propertyService.getAllProperties();
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách tất cả khu trọ thành công", properties));
    }
}
