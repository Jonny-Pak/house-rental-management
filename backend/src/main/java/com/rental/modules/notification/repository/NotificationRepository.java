package com.rental.modules.notification.repository;

import com.rental.modules.notification.domain.Notification;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    Slice<Notification> findByUserIdOrderByCreatedAtDescIdDesc(Long userId, Pageable pageable);
    Slice<Notification> findByUserIdAndReadFalseOrderByCreatedAtDescIdDesc(Long userId, Pageable pageable);
    long countByUserIdAndReadFalse(Long userId);
    boolean existsByIdAndUserId(Long id, Long userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update Notification n set n.read = true where n.id = :id and n.userId = :userId and n.read = false")
    int markRead(@Param("id") Long id, @Param("userId") Long userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update Notification n set n.read = true where n.userId = :userId and n.read = false")
    int markAllRead(@Param("userId") Long userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update Notification n set n.read = false where n.id = :id and n.userId = :userId and n.read = true")
    int markUnread(@Param("id") Long id, @Param("userId") Long userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from Notification n where n.id = :id and n.userId = :userId")
    int deleteOwned(@Param("id") Long id, @Param("userId") Long userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("delete from Notification n where n.userId = :userId and n.read = true")
    int deleteRead(@Param("userId") Long userId);
}
