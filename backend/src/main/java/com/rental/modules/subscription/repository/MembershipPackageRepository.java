package com.rental.modules.subscription.repository;

import com.rental.modules.subscription.domain.entity.MembershipPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MembershipPackageRepository extends JpaRepository<MembershipPackage, Short> {
    java.util.List<MembershipPackage> findByActiveTrueOrderByPriceAscIdAsc();
    boolean existsByPackageNameIgnoreCaseAndIdNot(String name, Short id);
    boolean existsByPackageNameIgnoreCase(String name);
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select p from MembershipPackage p where p.id = :id")
    java.util.Optional<MembershipPackage> findForUpdate(@org.springframework.data.repository.query.Param("id") Short id);
    @org.springframework.data.jpa.repository.Query("""
        select p from MembershipPackage p where locate(lower(:query), lower(p.packageName)) > 0
        and (:active is null or p.active = :active) order by p.id
        """)
    org.springframework.data.domain.Page<MembershipPackage> search(
        @org.springframework.data.repository.query.Param("query") String query,
        @org.springframework.data.repository.query.Param("active") Boolean active, org.springframework.data.domain.Pageable pageable);

}
