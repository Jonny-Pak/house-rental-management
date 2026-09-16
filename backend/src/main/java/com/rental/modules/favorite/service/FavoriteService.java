package com.rental.modules.favorite.service;

import com.rental.modules.favorite.domain.entity.FavoriteProperty;
import com.rental.modules.favorite.repository.FavoritePropertyRepository;
import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.property.domain.entity.PropertyImage;
import com.rental.modules.property.dto.response.PropertyResponse;
import com.rental.modules.property.repository.PropertyImageRepository;
import com.rental.modules.property.repository.PropertyRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final UserRepository userRepository;
    private final PropertyRepository propertyRepository;
    private final FavoritePropertyRepository favoritePropertyRepository;
    private final PropertyImageRepository propertyImageRepository;

    /**
     * Toggle favorite for a property.
     * @return true  if the property is now favorited,
     *         false if the property was removed from favorites.
     */
    @Transactional
    public boolean toggleFavorite(String email, Long propertyId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với email: " + email));

        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy khu trọ với ID: " + propertyId));

        boolean alreadyFavorited = favoritePropertyRepository
                .existsByUser_UserIdAndProperty_Id(user.getUserId(), propertyId);

        if (alreadyFavorited) {
            favoritePropertyRepository.deleteByUser_UserIdAndProperty_Id(user.getUserId(), propertyId);
            return false;
        } else {
            FavoriteProperty favorite = FavoriteProperty.builder()
                    .user(user)
                    .property(property)
                    .build();
            favoritePropertyRepository.save(favorite);
            return true;
        }
    }

    /**
     * Get all favorited properties for the authenticated user.
     */
    public List<PropertyResponse> getMyFavoriteProperties(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với email: " + email));

        return favoritePropertyRepository.findByUser_UserId(user.getUserId()).stream()
                .map(fav -> mapToResponse(fav.getProperty()))
                .collect(Collectors.toList());
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
                .propertyType(property.getPropertyType())
                .status(property.getStatus())
                .landlordPhone(property.getLandlord().getPhoneNumber())
                .imageUrls(imageUrls)
                .build();
    }
}
