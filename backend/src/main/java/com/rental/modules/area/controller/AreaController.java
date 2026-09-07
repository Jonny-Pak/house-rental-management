package com.rental.modules.area.controller;

import com.rental.modules.area.dto.DistrictDto;
import com.rental.modules.area.dto.ProvinceDto;
import com.rental.modules.area.dto.WardDto;
import com.rental.modules.area.service.AreaService;
import com.rental.modules.user.dto.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/areas")
@RequiredArgsConstructor
public class AreaController {

    private final AreaService areaService;

    @GetMapping("/provinces")
    public ResponseEntity<ApiResponse<List<ProvinceDto>>> getAllProvinces() {
        List<ProvinceDto> provinces = areaService.getAllProvinces();
        return ResponseEntity.ok(ApiResponse.success("Provinces fetched successfully.", provinces));
    }

    @GetMapping("/provinces/{provinceId}/districts")
    public ResponseEntity<ApiResponse<List<DistrictDto>>> getDistrictsByProvince(
            @PathVariable Long provinceId) {
        List<DistrictDto> districts = areaService.getDistrictsByProvince(provinceId);
        return ResponseEntity.ok(ApiResponse.success("Districts fetched successfully.", districts));
    }

    @GetMapping("/districts/{districtId}/wards")
    public ResponseEntity<ApiResponse<List<WardDto>>> getWardsByDistrict(
            @PathVariable Long districtId) {
        List<WardDto> wards = areaService.getWardsByDistrict(districtId);
        return ResponseEntity.ok(ApiResponse.success("Wards fetched successfully.", wards));
    }
}
