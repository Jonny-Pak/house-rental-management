package com.rental.modules.user.repository;

import com.rental.modules.user.domain.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    java.util.List<User> findByRoleAndStatus(com.rental.modules.user.domain.enums.Role role, com.rental.modules.user.domain.enums.UserStatus status);

    @org.springframework.data.jpa.repository.Query("select u.userId from User u where u.status = :status and u.isVerified = true")
    java.util.List<Long> findVerifiedIds(@org.springframework.data.repository.query.Param("status") com.rental.modules.user.domain.enums.UserStatus status);

    Optional<User> findByEmail(String email);

    Optional<User> findByPhoneNumber(String phoneNumber);

    java.util.List<User> findByPhoneNumberIn(java.util.List<String> phoneNumbers);

    boolean existsByEmail(String email);
}
