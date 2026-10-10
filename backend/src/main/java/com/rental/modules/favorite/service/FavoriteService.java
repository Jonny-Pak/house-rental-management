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
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class FavoriteService {

    private final UserRepository userRepository;
    private final PropertyRepository propertyRepository;
    private final FavoritePropertyRepository favoritePropertyRepository;
    private final PropertyImageRepository propertyImageRepository;

    public FavoriteService(UserRepository userRepository, PropertyRepository propertyRepository, FavoritePropertyRepository favoritePropertyRepository, PropertyImageRepository propertyImageRepository) {
        this.userRepository = userRepository;
        this.propertyRepository = propertyRepository;
        this.favoritePropertyRepository = favoritePropertyRepository;
        this.propertyImageRepository = propertyImageRepository;
    }


    /**
     * Toggle favorite for a property.
     * @return true  if the property is now favorited,
     *         false if the property was removed from favorites.
     */
    @Transactional
    public boolean toggleFavorite(String email, Long propertyId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email));

        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new IllegalArgumentException("KhÃ´ng tÃ¬m tháº¥y khu trá» vá»›i ID: " + propertyId));

        boolean alreadyFavorited = favoritePropertyRepository
                .existsByUser_UserIdAndProperty_Id(user.getUserId(), propertyId);

        if (alreadyFavorited) {
            favoritePropertyRepository.deleteByUser_UserIdAndProperty_Id(user.getUserId(), propertyId);
            return false;
        } else {
            FavoriteProperty favorite = new FavoriteProperty(user, property);
            favoritePropertyRepository.save(favorite);
            return true;
        }
    }

    /**
     * Get all favorited properties for the authenticated user.
     */
    public List<PropertyResponse> getMyFavoriteProperties(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email));

        return favoritePropertyRepository.findByUser_UserId(user.getUserId()).stream()
                .map(fav -> mapToResponse(fav.getProperty()))
                .collect(Collectors.toList());
    }

    private PropertyResponse mapToResponse(Property property) {
        List<String> imageUrls = propertyImageRepository.findByPropertyId(property.getId()).stream()
                .map(PropertyImage::getImageUrl)
                .collect(Collectors.toList());

        return new PropertyResponse(
                property.getId(),
                property.getLandlord().getUserId(),
                property.getName(),
                property.getDescription(),
                property.getAddress(),
                property.getProvinceId(),
                property.getDistrictId(),
                property.getWardId(),
                property.getElectricityPrice(),
                property.getWaterPrice(),
                property.getPropertyType(),
                property.getStatus(),
                property.getLandlord().getFullName(),
                property.getLandlord().getPhoneNumber(),
                imageUrls
        );
    }
}
