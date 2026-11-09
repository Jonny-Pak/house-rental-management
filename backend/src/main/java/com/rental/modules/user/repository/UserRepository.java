package com.rental.modules.user.repository;

import com.rental.modules.user.domain.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    @org.springframework.data.jpa.repository.Query(value = "SELECT count(*) FROM tin_cho_thue WHERE ma_chu_tin=:userId AND trang_thai_cho_thue <> 'DELETED'", nativeQuery = true)
    long countListingsForUser(@org.springframework.data.repository.query.Param("userId") Long userId);

    @org.springframework.data.jpa.repository.Query(value = "SELECT count(*) FROM hop_dong_thue WHERE ma_ben_cho_thue=:userId OR ma_ben_thue=:userId", nativeQuery = true)
    long countContractsForUser(@org.springframework.data.repository.query.Param("userId") Long userId);

    @org.springframework.data.jpa.repository.Query(value = "SELECT count(*) FROM tin_yeu_thich f JOIN tin_cho_thue l ON l.ma_tin_dang=f.ma_tin_dang WHERE f.ma_nguoi_dung=:userId AND l.trang_thai_kiem_duyet='APPROVED' AND l.trang_thai_cho_thue='AVAILABLE'", nativeQuery = true)
    long countSavedListingsForUser(@org.springframework.data.repository.query.Param("userId") Long userId);

    @org.springframework.data.jpa.repository.Query("""
        select u from User u where
        (locate(lower(:query), lower(u.fullName)) > 0 or locate(lower(:query), lower(u.email)) > 0
            or locate(:query, u.phoneNumber) > 0)
        and (:role is null or u.role = :role) and (:status is null or u.status = :status)
        and (:verified is null or u.isVerified = :verified or (:verified = false and u.isVerified is null))
        """)
    org.springframework.data.domain.Page<User> searchForAdmin(
        @org.springframework.data.repository.query.Param("query") String query,
        @org.springframework.data.repository.query.Param("role") com.rental.modules.user.domain.enums.Role role,
        @org.springframework.data.repository.query.Param("status") com.rental.modules.user.domain.enums.UserStatus status,
        @org.springframework.data.repository.query.Param("verified") Boolean verified,
        org.springframework.data.domain.Pageable pageable);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select u from User u where u.userId = :id")
    Optional<User> findForAdminUpdate(@org.springframework.data.repository.query.Param("id") Long id);

    java.util.List<User> findByRoleAndStatus(com.rental.modules.user.domain.enums.Role role, com.rental.modules.user.domain.enums.UserStatus status);

    @org.springframework.data.jpa.repository.Query("select u.userId from User u where u.status = :status and u.isVerified = true")
    java.util.List<Long> findVerifiedIds(@org.springframework.data.repository.query.Param("status") com.rental.modules.user.domain.enums.UserStatus status);

    Optional<User> findByEmail(String email);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select u from User u where lower(u.email) = lower(:email)")
    Optional<User> findForPasswordUpdate(@org.springframework.data.repository.query.Param("email") String email);

    Optional<User> findByPhoneNumber(String phoneNumber);

    java.util.List<User> findByPhoneNumberIn(java.util.List<String> phoneNumbers);

    boolean existsByEmail(String email);

    boolean existsByEmailIgnoreCase(String email);
    Optional<User> findByGoogleId(String googleId);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select u from User u where lower(u.email) = lower(:email)")
    java.util.List<User> findGoogleEmailMatches(@org.springframework.data.repository.query.Param("email") String email);
}
