package com.rental.modules.listing.repository;

import com.rental.modules.listing.domain.entity.Listing;
import org.locationtech.jts.geom.Polygon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;

@Repository
public interface ListingRepository extends JpaRepository<Listing, Long> {

    @Query("SELECT l FROM Listing l " +
           "WHERE l.location IS NOT NULL " +
           "AND within(l.location, :bbox) = true " +
           "AND l.approvalStatus = 'APPROVED' " +
           "AND l.rentalStatus = 'AVAILABLE'")
    List<Listing> findListingsWithinBoundingBox(@Param("bbox") Polygon bbox);

    List<Listing> findByApprovalStatus(String approvalStatus);
    List<Listing> findByApprovalStatusAndRentalStatusOrderByCreatedAtDesc(String approvalStatus, String rentalStatus);
    List<Listing> findByOwner_UserIdAndRentalStatusNotOrderByCreatedAtDesc(Long ownerId, String excludedStatus);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select l from Listing l where l.id = :id")
    Optional<Listing> findLockedById(@Param("id") Long id);
}
