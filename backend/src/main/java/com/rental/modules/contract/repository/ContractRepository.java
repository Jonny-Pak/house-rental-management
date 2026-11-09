package com.rental.modules.contract.repository;

import com.rental.modules.contract.domain.entity.Contract;
import com.rental.modules.user.domain.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContractRepository extends JpaRepository<Contract, Long> {
    List<Contract> findByLandlordOrTenant(User landlord, User tenant);
    List<Contract> findByLandlordOrTenantOrderByListing_IdAscIdAsc(User landlord, User tenant);
    List<Contract> findByLandlordOrTenantOrderByIdDesc(User landlord, User tenant);
    boolean existsByListing_IdAndStatusInAndIdNot(Long listingId, List<String> statuses, Long id);
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select c from Contract c where c.id=:id")
    java.util.Optional<Contract> findLockedById(@org.springframework.data.repository.query.Param("id") Long id);
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"listing", "landlord", "tenant"})
    @org.springframework.data.jpa.repository.Query("""
        select c from Contract c where
        (:status = '' or
          (:status = 'EXPIRED' and (c.status = 'EXPIRED' or (c.status = 'ACTIVE' and c.endDate < :today))) or
          (:status = 'ACTIVE' and c.status = 'ACTIVE' and c.endDate >= :today) or
          (:status not in ('ACTIVE', 'EXPIRED') and c.status = :status))
        and (:type = '' or coalesce(c.contractType, case when c.listing.listingType in ('BOARDING_ROOM', 'SHARED_ROOM') then 'ROOM' else 'HOUSE' end) = :type)
        and (:query = '' or c.id = :id or
          locate(:query, lower(concat(coalesce(c.listingTitle, ''), ' ', coalesce(c.listingAddress, ''), ' ',
            coalesce(c.landlord.fullName, ''), ' ', coalesce(c.landlord.email, ''), ' ', coalesce(c.landlord.phoneNumber, ''), ' ',
            coalesce(c.tenant.fullName, ''), ' ', coalesce(c.tenant.email, ''), ' ', coalesce(c.tenant.phoneNumber, ''), ' ',
            coalesce(c.detailsJson, '')))) > 0)
        """)
    org.springframework.data.domain.Page<Contract> searchAdmin(
        @org.springframework.data.repository.query.Param("query") String query,
        @org.springframework.data.repository.query.Param("id") Long id,
        @org.springframework.data.repository.query.Param("status") String status,
        @org.springframework.data.repository.query.Param("type") String type,
        @org.springframework.data.repository.query.Param("today") java.time.LocalDate today,
        org.springframework.data.domain.Pageable pageable);

    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"listing", "landlord", "tenant"})
    @org.springframework.data.jpa.repository.Query("select c from Contract c where c.id = :id")
    java.util.Optional<Contract> findAdminDetail(@org.springframework.data.repository.query.Param("id") Long id);
}
