package com.rental.modules.amenity.controller;

import com.rental.core.dto.ApiResponse;
import com.rental.modules.amenity.dto.AmenityResponse;
import com.rental.modules.amenity.service.AmenityService;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/amenities")
public class AmenityController {
    private final AmenityService service;
    public AmenityController(AmenityService service) { this.service = service; }
    @GetMapping public ApiResponse<List<AmenityResponse>> list() { return ApiResponse.success("Danh mục đang sử dụng.", service.activeItems()); }
}
