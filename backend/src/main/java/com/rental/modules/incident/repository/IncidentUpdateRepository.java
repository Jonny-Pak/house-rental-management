package com.rental.modules.incident.repository;
import com.rental.modules.incident.domain.entity.IncidentUpdate;
import org.springframework.data.jpa.repository.*;
import java.util.List;
public interface IncidentUpdateRepository extends JpaRepository<IncidentUpdate, Long> {
    @EntityGraph(attributePaths = "actor")
    List<IncidentUpdate> findByIncidentIdOrderByCreatedAtAscIdAsc(Long incidentId);
}
