package com.rental.modules.listing.repository;

import com.rental.modules.listing.entity.Listing;
import org.locationtech.jts.geom.Polygon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ListingRepository extends JpaRepository<Listing, Long> {

    /**
     * Tìm tất cả Listing đã được duyệt và đang còn trống nằm trong vùng bounding box.
     * Dùng hàm within() của Hibernate Spatial (ánh xạ sang ST_Within của PostGIS).
     * Chú ý: chỉ lọc các Listing CÓ tọa độ (location IS NOT NULL).
     */
    @Query("SELECT l FROM Listing l " +
           "WHERE l.location IS NOT NULL " +
           "AND within(l.location, :bbox) = true " +
           "AND l.approvalStatus = 'APPROVED' " +
           "AND l.rentalStatus = 'AVAILABLE'")
    List<Listing> findListingsWithinBoundingBox(@Param("bbox") Polygon bbox);
}