package com.rental.modules.area.service;

import com.rental.modules.area.dto.DistrictDto;
import com.rental.modules.area.dto.ProvinceDto;
import com.rental.modules.area.dto.WardDto;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AreaService {

    private final AdministrativeAreaRepository areaRepository;

    public AreaService(AdministrativeAreaRepository areaRepository) {
        this.areaRepository = areaRepository;
    }

    public List<ProvinceDto> getAllProvinces() {
        return areaRepository.findByAreaTypeOrderByAreaNameAsc("PROVINCE")
                .stream()
                .map(area -> new ProvinceDto(
                        area.getAreaId(),
                        area.getAreaName(),
                        area.getCode()
                ))
                .collect(Collectors.toList());
    }

    public List<DistrictDto> getDistrictsByProvince(Long provinceId) {
        return areaRepository.findByParent_AreaIdAndAreaTypeOrderByAreaNameAsc(provinceId, "DISTRICT")
                .stream()
                .map(area -> new DistrictDto(
                        area.getAreaId(),
                        area.getAreaName(),
                        area.getCode(),
                        area.getParent() != null ? area.getParent().getAreaId() : null
                ))
                .collect(Collectors.toList());
    }

    public List<WardDto> getWardsByDistrict(Long districtId) {
        return areaRepository.findByParent_AreaIdAndAreaTypeOrderByAreaNameAsc(districtId, "WARD")
                .stream()
                .map(area -> new WardDto(
                        area.getAreaId(),
                        area.getAreaName(),
                        area.getCode(),
                        area.getParent() != null ? area.getParent().getAreaId() : null
                ))
                .collect(Collectors.toList());
    }
}
