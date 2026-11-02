package com.rental.modules.content.repository;

import com.rental.modules.content.domain.entity.SystemContent;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface SystemContentRepository extends JpaRepository<SystemContent, String> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from SystemContent c where c.slug = :slug")
    Optional<SystemContent> findForUpdate(@Param("slug") String slug);
}
