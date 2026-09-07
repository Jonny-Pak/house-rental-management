package com.rental.modules.area.service;

import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.area.dto.DistrictDto;
import com.rental.modules.area.dto.ProvinceDto;
import com.rental.modules.area.dto.WardDto;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AreaService {

    private final AdministrativeAreaRepository areaRepository;

    public List<ProvinceDto> getAllProvinces() {
        return areaRepository.findByAreaTypeOrderByAreaNameAsc("PROVINCE")
                .stream()
                .map(area -> ProvinceDto.builder()
                        .id(area.getAreaId())
                        .name(area.getAreaName())
                        .code(area.getCode())
                        .build())
                .collect(Collectors.toList());
    }

    public List<DistrictDto> getDistrictsByProvince(Long provinceId) {
        return areaRepository.findByParent_AreaIdAndAreaTypeOrderByAreaNameAsc(provinceId, "DISTRICT")
                .stream()
                .map(area -> DistrictDto.builder()
                        .id(area.getAreaId())
                        .name(area.getAreaName())
                        .code(area.getCode())
                        .provinceId(area.getParent() != null ? area.getParent().getAreaId() : null)
                        .build())
                .collect(Collectors.toList());
    }

    public List<WardDto> getWardsByDistrict(Long districtId) {
        return areaRepository.findByParent_AreaIdAndAreaTypeOrderByAreaNameAsc(districtId, "WARD")
                .stream()
                .map(area -> WardDto.builder()
                        .id(area.getAreaId())
                        .name(area.getAreaName())
                        .code(area.getCode())
                        .districtId(area.getParent() != null ? area.getParent().getAreaId() : null)
                        .build())
                .collect(Collectors.toList());
    }
}
