package com.rental.modules.area.service;

import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.area.dto.DistrictDto;
import com.rental.modules.area.dto.ProvinceDto;
import com.rental.modules.area.dto.WardDto;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class AreaService {
    private final AdministrativeAreaRepository areaRepository;

    public AreaService(AdministrativeAreaRepository areaRepository) {
        this.areaRepository = areaRepository;
    }

    public List<ProvinceDto> getAllProvinces() {
        List<ProvinceDto> result = new ArrayList<>();
        List<AdministrativeArea> provinces = areaRepository.findByAreaTypeOrderByAreaNameAsc("PROVINCE");
        for (AdministrativeArea province : provinces) {
            result.add(new ProvinceDto(province.getAreaId(), province.getAreaName(), province.getCode()));
        }
        return result;
    }

    public List<DistrictDto> getDistrictsByProvince(Long provinceId) {
        List<DistrictDto> result = new ArrayList<>();
        List<AdministrativeArea> districts = areaRepository.findByParent_AreaIdAndAreaTypeOrderByAreaNameAsc(provinceId, "DISTRICT");
        for (AdministrativeArea district : districts) {
            Long parentId = getParentId(district);
            result.add(new DistrictDto(district.getAreaId(), district.getAreaName(), district.getCode(), parentId));
        }
        return result;
    }

    public List<WardDto> getWardsByDistrict(Long districtId) {
        List<WardDto> result = new ArrayList<>();
        List<AdministrativeArea> wards = areaRepository.findByParent_AreaIdAndAreaTypeOrderByAreaNameAsc(districtId, "WARD");
        for (AdministrativeArea ward : wards) {
            result.add(new WardDto(ward.getAreaId(), ward.getAreaName(), ward.getCode(), getParentId(ward)));
        }
        return result;
    }

    public List<WardDto> getWardsByProvince(Long provinceId) {
        List<WardDto> result = new ArrayList<>();
        List<AdministrativeArea> wards = areaRepository.findByParent_AreaIdAndAreaTypeInOrderByAreaNameAsc(
                provinceId, List.of("WARD", "COMMUNE", "SPECIAL"));
        for (AdministrativeArea ward : wards) {
            WardDto response = new WardDto(ward.getAreaId(), ward.getAreaName(), ward.getCode(), null);
            response.setProvinceId(provinceId);
            response.setType(ward.getAreaType());
            result.add(response);
        }
        return result;
    }

    private Long getParentId(AdministrativeArea area) {
        if (area.getParent() == null) {
            return null;
        }
        return area.getParent().getAreaId();
    }
}
