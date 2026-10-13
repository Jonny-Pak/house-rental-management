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
}
