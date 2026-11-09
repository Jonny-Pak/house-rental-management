package com.rental.modules.amenity.repository;

import com.rental.modules.amenity.domain.entity.Amenity;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface AmenityRepository extends JpaRepository<Amenity, Long> {
    List<Amenity> findByActiveTrueOrderByCategoryAscNameAsc();

    @Query("select a from Amenity a where locate(lower(:query),lower(a.name))>0 and (:category is null or a.category=:category) and (:active is null or a.active=:active)")
    Page<Amenity> search(@Param("query") String query, @Param("category") String category, @Param("active") Boolean active, Pageable pageable);

    boolean existsByCategoryAndNameIgnoreCase(String category, String name);
    boolean existsByCategoryAndNameIgnoreCaseAndIdNot(String category, String name, Long id);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Amenity a where a.id=:id")
    Optional<Amenity> findForUpdate(@Param("id") Long id);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Amenity a where a.id in :ids order by a.id")
    List<Amenity> findSelectedForUpdate(@Param("ids") List<Long> ids);

    @Query(value = "select count(*) from tien_ich_cua_tin_dang where ma_tien_ich=:id", nativeQuery = true)
    long countListings(@Param("id") Long id);
}
