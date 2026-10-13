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
import java.util.ArrayList;

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

    @Transactional
    public boolean toggleFavorite(String email, Long propertyId) {
        java.util.Optional<User> userResult = userRepository.findByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email);
        }
        User user = userResult.get();

        java.util.Optional<Property> propertyResult = propertyRepository.findById(propertyId);
        if (propertyResult.isEmpty()) {
            throw new IllegalArgumentException("KhÃ´ng tÃ¬m tháº¥y khu trá» vá»›i ID: " + propertyId);
        }
        Property property = propertyResult.get();

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

    public List<PropertyResponse> getMyFavoriteProperties(String email) {
        java.util.Optional<User> userResult = userRepository.findByEmail(email);
        if (userResult.isEmpty()) {
            throw new IllegalArgumentException("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng vá»›i email: " + email);
        }
        User user = userResult.get();

        List<PropertyResponse> result = new ArrayList<>();
        List<FavoriteProperty> favorites = favoritePropertyRepository.findByUser_UserId(user.getUserId());
        for (FavoriteProperty favorite : favorites) {
            result.add(mapToResponse(favorite.getProperty()));
        }
        return result;
    }

    private PropertyResponse mapToResponse(Property property) {
        List<String> imageUrls = new ArrayList<>();
        List<PropertyImage> images = propertyImageRepository.findByPropertyId(property.getId());
        for (PropertyImage image : images) {
            imageUrls.add(image.getImageUrl());
        }

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
