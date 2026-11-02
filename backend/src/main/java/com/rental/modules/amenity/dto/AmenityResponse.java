package com.rental.modules.amenity.dto;

import com.rental.modules.amenity.domain.entity.Amenity;

public record AmenityResponse(Long id, String name, String category, String description, boolean active, Long version, Long listingCount) {
    public static AmenityResponse from(Amenity item, Long listingCount) {
        return new AmenityResponse(item.getId(), item.getName(), item.getCategory(), item.getDescription(), item.isActive(), item.getVersion(), listingCount);
    }
}
