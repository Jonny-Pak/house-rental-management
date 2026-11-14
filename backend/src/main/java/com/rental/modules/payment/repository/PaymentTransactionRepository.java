package com.rental.modules.payment.repository;

import com.rental.modules.payment.domain.entity.PaymentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {
    java.util.List<PaymentTransaction> findTop20ByUser_UserIdOrderByTransactionDateDescIdDesc(Long userId);
    Optional<PaymentTransaction> findByVnpayTransactionRef(String vnpayTransactionRef);
    boolean existsByPurchasedPackageId(Short id);
    boolean existsByUser_UserIdAndPurchasedPackage_IdAndStatusAndTransactionDateAfter(
            Long userId, Short packageId, String status, java.time.LocalDateTime after);
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select p from PaymentTransaction p where p.vnpayTransactionRef = :ref")
    Optional<PaymentTransaction> findForUpdate(@org.springframework.data.repository.query.Param("ref") String ref);
}

