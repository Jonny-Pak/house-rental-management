package com.rental.modules.user.qr;

import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;

public interface QrLoginRepository extends JpaRepository<QrLoginSession, String> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select q from QrLoginSession q where q.id = :id")
    Optional<QrLoginSession> findForUpdate(@Param("id") String id);

    long countByRequesterHashAndCreatedAtAfter(String requesterHash, Instant since);

    @Modifying
    @Query("delete from QrLoginSession q where q.expiresAt < :cutoff")
    void deleteExpired(@Param("cutoff") Instant cutoff);
}
