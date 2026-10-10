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
import java.util.stream.Collectors;

@Service
public class PropertyService {

    private final PropertyRepository propertyRepository;
    private final PropertyImageRepository propertyImageRepository;
    private final UserRepository userRepository;

    public PropertyService(PropertyRepository propertyRepository, PropertyImageRepository propertyImageRepository, UserRepository userRepository) {
        this.propertyRepository = propertyRepository;
        this.propertyImageRepository = propertyImageRepository;
        this.userRepository = userRepository;
    }


    @Transactional
    public PropertyResponse createProperty(String email, PropertyRequest request) {
        User landlord = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email));

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

        // Save Property Images if any
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            List<PropertyImage> images = request.getImageUrls().stream()
                    .map(url -> {
                        PropertyImage img = new PropertyImage();
                        img.setProperty(savedProperty);
                        img.setImageUrl(url);
                        return img;
                    })
                    .collect(Collectors.toList());
            propertyImageRepository.saveAll(images);
        }

        return mapToResponse(savedProperty);
    }

    @Transactional(readOnly = true)
    public List<PropertyResponse> getMyProperties(String email) {
        User landlord = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email));

        return propertyRepository.findByLandlord(landlord).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PropertyResponse getPropertyById(Long id) {
        Property property = propertyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("KhÃ´ng tÃ¬m tháº¥y khu trá» vá»›i ID: " + id));
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

        return propertyRepository.findAll(spec).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private PropertyResponse mapToResponse(Property property) {
        List<String> imageUrls = propertyImageRepository.findByPropertyId(property.getId()).stream()
                .map(PropertyImage::getImageUrl)
                .collect(Collectors.toList());

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
