package com.rental.modules.incident.repository;

import com.rental.modules.incident.domain.entity.IncidentReport;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.*;
import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;
import java.util.Optional;

public interface IncidentRepository extends JpaRepository<IncidentReport, Long> {
    @EntityGraph(attributePaths = "reporter")
    @Query("""
        select r from IncidentReport r where (:reporter is null or r.reporter.userId = :reporter)
        and (:status is null or r.status = :status) and (:category is null or r.category = :category)
        and (locate(lower(:query), lower(r.title)) > 0 or locate(lower(:query), lower(r.description)) > 0
          or locate(lower(:query), lower(r.reporter.fullName)) > 0)
        """)
    Page<IncidentReport> search(@Param("reporter") Long reporter, @Param("status") String status,
        @Param("category") String category, @Param("query") String query, Pageable pageable);
    Optional<IncidentReport> findByReporterUserIdAndRequestKey(Long reporterId, String requestKey);
    boolean existsByReporterUserIdAndCreatedAtAfter(Long reporterId, LocalDateTime since);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from IncidentReport r where r.id = :id")
    Optional<IncidentReport> findForUpdate(@Param("id") Long id);
}
