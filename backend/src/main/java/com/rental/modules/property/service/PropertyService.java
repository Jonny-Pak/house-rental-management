package com.rental.modules.property.service;

import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.property.domain.entity.PropertyImage;
import com.rental.modules.property.dto.request.PropertyRequest;
import com.rental.modules.property.dto.response.PropertyResponse;
import com.rental.modules.property.repository.PropertyImageRepository;
import com.rental.modules.property.repository.PropertyRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.ArrayList;

@Service
public class PropertyService {

    private final PropertyRepository propertyRepository;
    private final PropertyImageRepository propertyImageRepository;
    private final UserRepository userRepository;
    private final com.rental.modules.area.repository.AdministrativeAreaRepository areaRepository;

    public PropertyService(PropertyRepository propertyRepository, PropertyImageRepository propertyImageRepository, UserRepository userRepository,
            com.rental.modules.area.repository.AdministrativeAreaRepository areaRepository) {
        this.propertyRepository = propertyRepository;
        this.propertyImageRepository = propertyImageRepository;
        this.userRepository = userRepository;
        this.areaRepository = areaRepository;
    }

    @Transactional
    public PropertyResponse createProperty(String email, PropertyRequest request) {
        java.util.Optional<com.rental.modules.area.domain.entity.AdministrativeArea> wardResult = areaRepository.findById(request.getWardId());
        if (wardResult.isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST, "Phường/xã/đặc khu không hợp lệ.");
        }
        com.rental.modules.area.domain.entity.AdministrativeArea ward = wardResult.get();
        com.rental.modules.area.domain.entity.AdministrativeArea parent = ward.getParent();
        if (!ward.isAvailable() || !List.of("WARD", "COMMUNE", "SPECIAL").contains(ward.getAreaType()) || parent == null) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST, "Phường/xã/đặc khu không hợp lệ.");
        }
        Long provinceId = null;
        Long districtId = null;
        if ("PROVINCE".equals(parent.getAreaType())) {
            provinceId = parent.getAreaId();
        } else if (parent.getParent() != null) {
            provinceId = parent.getParent().getAreaId();
        }
        if ("DISTRICT".equals(parent.getAreaType())) {
            districtId = parent.getAreaId();
        }
        if (!java.util.Objects.equals(provinceId, request.getProvinceId())
                || !java.util.Objects.equals(districtId, request.getDistrictId())) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST, "Địa chỉ hành chính không khớp với phường/xã đã chọn.");
        }
        java.util.Optional<User> landlordResult = userRepository.findByEmail(email);
        if (landlordResult.isEmpty()) {
            throw new RuntimeException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email);
        }
        User landlord = landlordResult.get();

        Property property = new Property();
        property.setLandlord(landlord);
        property.setName(request.getName());
        property.setDescription(request.getDescription());
        property.setAddress(request.getAddress());
        property.setProvinceId(request.getProvinceId());
        property.setDistrictId(request.getDistrictId());
        property.setWardId(request.getWardId());
        property.setPropertyType(request.getPropertyType());
        property.setElectricityPrice(request.getElectricityPrice());
        property.setWaterPrice(request.getWaterPrice());

        Property savedProperty = propertyRepository.save(property);

        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            List<PropertyImage> images = new ArrayList<>();
            for (String url : request.getImageUrls()) {
                PropertyImage image = new PropertyImage();
                image.setProperty(savedProperty);
                image.setImageUrl(url);
                images.add(image);
            }
            propertyImageRepository.saveAll(images);
        }

        return mapToResponse(savedProperty);
    }

    @Transactional(readOnly = true)
    public List<PropertyResponse> getMyProperties(String email) {
        java.util.Optional<User> landlordResult = userRepository.findByEmail(email);
        if (landlordResult.isEmpty()) {
            throw new RuntimeException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email);
        }
        User landlord = landlordResult.get();

        List<Property> properties = propertyRepository.findByLandlord(landlord);
        return toResponses(properties);
    }

    @Transactional(readOnly = true)
    public PropertyResponse getPropertyById(Long id) {
        java.util.Optional<Property> propertyResult = propertyRepository.findById(id);
        if (propertyResult.isEmpty()) {
            throw new RuntimeException("KhÃ´ng tÃ¬m tháº¥y khu trá» vá»›i ID: " + id);
        }
        Property property = propertyResult.get();
        return mapToResponse(property);
    }

    @Transactional(readOnly = true)
    public List<PropertyResponse> getAllProperties(
            Long provinceId,
            Long districtId,
            Long wardId,
            String propertyType,
            java.math.BigDecimal minPrice,
            java.math.BigDecimal maxPrice) {

        org.springframework.data.jpa.domain.Specification<Property> spec = org.springframework.data.jpa.domain.Specification.where(
                com.rental.modules.property.specification.PropertySpecification.hasProvinceId(provinceId))
                .and(com.rental.modules.property.specification.PropertySpecification.hasDistrictId(districtId))
                .and(com.rental.modules.property.specification.PropertySpecification.hasWardId(wardId))
                .and(com.rental.modules.property.specification.PropertySpecification.hasPropertyType(propertyType))
                .and(com.rental.modules.property.specification.PropertySpecification.hasRoomPriceBetween(minPrice, maxPrice));

        List<Property> properties = propertyRepository.findAll(spec);
        return toResponses(properties);
    }

    private List<PropertyResponse> toResponses(List<Property> properties) {
        List<PropertyResponse> result = new ArrayList<>();
        for (Property property : properties) {
            result.add(mapToResponse(property));
        }
        return result;
    }

    private PropertyResponse mapToResponse(Property property) {
        List<String> imageUrls = new ArrayList<>();
        List<PropertyImage> images = propertyImageRepository.findByPropertyId(property.getId());
        for (PropertyImage image : images) {
            imageUrls.add(image.getImageUrl());
        }

        PropertyResponse response = new PropertyResponse();
        response.setId(property.getId());
        response.setLandlordId(property.getLandlord().getUserId());
        response.setName(property.getName());
        response.setDescription(property.getDescription());
        response.setAddress(property.getAddress());
        response.setProvinceId(property.getProvinceId());
        response.setDistrictId(property.getDistrictId());
        response.setWardId(property.getWardId());
        response.setElectricityPrice(property.getElectricityPrice());
        response.setWaterPrice(property.getWaterPrice());
        response.setPropertyType(property.getPropertyType());
        response.setStatus(property.getStatus());
        response.setLandlordName(property.getLandlord().getFullName());
        response.setLandlordPhone(property.getLandlord().getPhoneNumber());
        response.setImageUrls(imageUrls);
        return response;
    }
}
