package com.rental.modules.payment.domain.entity;

import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payment_transactions")
public class PaymentTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "transaction_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subscription_id")
    private UserSubscription subscription;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Column(name = "payment_method", length = 20)
    private String paymentMethod = "VNPAY";

    @Column(name = "vnpay_transaction_ref", length = 100)
    private String vnpayTransactionRef;

    @Column(nullable = false, length = 15)
    private String status = "PENDING";

    @Column(name = "transaction_date", updatable = false)
    private LocalDateTime transactionDate = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "package_id")
    private com.rental.modules.subscription.domain.entity.MembershipPackage purchasedPackage;
    @Column(name = "package_name_snapshot", length = 20)
    private String packageNameSnapshot;
    @Column(name = "standard_quota_snapshot") private Short standardQuotaSnapshot;
    @Column(name = "vip_quota_snapshot") private Short vipQuotaSnapshot;
    @Column(name = "refresh_quota_snapshot") private Short refreshQuotaSnapshot;
    public com.rental.modules.subscription.domain.entity.MembershipPackage getPurchasedPackage() { return purchasedPackage; }
    public void setPurchasedPackage(com.rental.modules.subscription.domain.entity.MembershipPackage value) { purchasedPackage = value; }
    public String getPackageNameSnapshot() { return packageNameSnapshot; }
    public void setPackageNameSnapshot(String value) { packageNameSnapshot = value; }
    public Short getStandardQuotaSnapshot() { return standardQuotaSnapshot; }
    public void setStandardQuotaSnapshot(Short value) { standardQuotaSnapshot = value; }
    public Short getVipQuotaSnapshot() { return vipQuotaSnapshot; }
    public void setVipQuotaSnapshot(Short value) { vipQuotaSnapshot = value; }
    public Short getRefreshQuotaSnapshot() { return refreshQuotaSnapshot; }
    public void setRefreshQuotaSnapshot(Short value) { refreshQuotaSnapshot = value; }

    public PaymentTransaction() {}
    public PaymentTransaction(Long id, User user, UserSubscription subscription, BigDecimal amount, String paymentMethod, String vnpayTransactionRef, String status, LocalDateTime transactionDate) {
        this.id = id;
        this.user = user;
        this.subscription = subscription;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
        this.vnpayTransactionRef = vnpayTransactionRef;
        this.status = status;
        this.transactionDate = transactionDate;
    }
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }
    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }
    public UserSubscription getSubscription() {
        return subscription;
    }

    public void setSubscription(UserSubscription subscription) {
        this.subscription = subscription;
    }
    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
    public String getVnpayTransactionRef() {
        return vnpayTransactionRef;
    }

    public void setVnpayTransactionRef(String vnpayTransactionRef) {
        this.vnpayTransactionRef = vnpayTransactionRef;
    }
    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
    public LocalDateTime getTransactionDate() {
        return transactionDate;
    }

    public void setTransactionDate(LocalDateTime transactionDate) {
        this.transactionDate = transactionDate;
    }

}

