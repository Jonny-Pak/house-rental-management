package com.rental.modules.property.service;

import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.property.domain.entity.PropertyImage;
import com.rental.modules.property.dto.request.PropertyRequest;
import com.rental.modules.property.dto.response.PropertyResponse;
import com.rental.modules.property.repository.PropertyImageRepository;
import com.rental.modules.property.repository.PropertyRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PropertyService {

    private final PropertyRepository propertyRepository;
    private final PropertyImageRepository propertyImageRepository;
    private final UserRepository userRepository;

    @Transactional
    public PropertyResponse createProperty(String email, PropertyRequest request) {
        User landlord = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với email: " + email));

        Property property = Property.builder()
                .landlord(landlord)
                .name(request.getName())
                .description(request.getDescription())
                .address(request.getAddress())
                .provinceId(request.getProvinceId())
                .districtId(request.getDistrictId())
                .wardId(request.getWardId())
                .electricityPrice(request.getElectricityPrice())
                .waterPrice(request.getWaterPrice())
                .build();

        Property savedProperty = propertyRepository.save(property);

        // Save Property Images if any
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            List<PropertyImage> images = request.getImageUrls().stream()
                    .map(url -> PropertyImage.builder()
                            .property(savedProperty)
                            .imageUrl(url)
                            .build())
                    .collect(Collectors.toList());
            propertyImageRepository.saveAll(images);
        }

        return mapToResponse(savedProperty);
    }

    @Transactional(readOnly = true)
    public List<PropertyResponse> getMyProperties(String email) {
        User landlord = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với email: " + email));

        return propertyRepository.findByLandlord(landlord).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PropertyResponse getPropertyById(Long id) {
        Property property = propertyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy khu trọ với ID: " + id));
        return mapToResponse(property);
    }

    private PropertyResponse mapToResponse(Property property) {
        List<String> imageUrls = propertyImageRepository.findByPropertyId(property.getId()).stream()
                .map(PropertyImage::getImageUrl)
                .collect(Collectors.toList());

        return PropertyResponse.builder()
                .id(property.getId())
                .landlordId(property.getLandlord().getUserId())
                .name(property.getName())
                .description(property.getDescription())
                .address(property.getAddress())
                .provinceId(property.getProvinceId())
                .districtId(property.getDistrictId())
                .wardId(property.getWardId())
                .electricityPrice(property.getElectricityPrice())
                .waterPrice(property.getWaterPrice())
                .status(property.getStatus())
                .imageUrls(imageUrls)
                .build();
    }
}
