package com.rental.modules.area.repository;

import com.rental.modules.area.domain.entity.AdministrativeArea;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AdministrativeAreaRepository extends JpaRepository<AdministrativeArea, Long> {

    List<AdministrativeArea> findByAreaTypeOrderByAreaNameAsc(String areaType);

    List<AdministrativeArea> findByParent_AreaIdAndAreaTypeOrderByAreaNameAsc(Long parentId, String areaType);
}
