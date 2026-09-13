package com.rental.modules.property.specification;

import com.rental.modules.property.domain.entity.Property;
import com.rental.modules.property.domain.entity.Room;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;

public class PropertySpecification {

    public static Specification<Property> hasProvinceId(Long provinceId) {
        return (root, query, cb) -> provinceId == null ? null : cb.equal(root.get("provinceId"), provinceId);
    }

    public static Specification<Property> hasDistrictId(Long districtId) {
        return (root, query, cb) -> districtId == null ? null : cb.equal(root.get("districtId"), districtId);
    }

    public static Specification<Property> hasWardId(Long wardId) {
        return (root, query, cb) -> wardId == null ? null : cb.equal(root.get("wardId"), wardId);
    }

    public static Specification<Property> hasPropertyType(String propertyType) {
        return (root, query, cb) -> (propertyType == null || propertyType.isEmpty()) ? null : cb.equal(root.get("propertyType"), propertyType);
    }

    public static Specification<Property> hasRoomPriceBetween(BigDecimal minPrice, BigDecimal maxPrice) {
        return (root, query, cb) -> {
            if (minPrice == null && maxPrice == null) {
                return null;
            }
            query.distinct(true);
            Join<Property, Room> roomJoin = root.join("rooms", JoinType.INNER);
            
            if (minPrice != null && maxPrice != null) {
                return cb.between(roomJoin.get("price"), minPrice, maxPrice);
            } else if (minPrice != null) {
                return cb.greaterThanOrEqualTo(roomJoin.get("price"), minPrice);
            } else {
                return cb.lessThanOrEqualTo(roomJoin.get("price"), maxPrice);
            }
        };
    }
}
