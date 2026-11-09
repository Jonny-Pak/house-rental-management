package com.rental.modules.payment.domain.entity;

import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "giao_dich_thanh_toan")
public class PaymentTransaction {
    @Column(name = "ma_ket_qua_vnpay", length = 2)
    private String responseCode;

    public String getResponseCode() { return responseCode; }
    public void setResponseCode(String value) { responseCode = value; }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_giao_dich")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_nguoi_dung", nullable = false)
    private User user;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_dang_ky_goi")
    private UserSubscription subscription;

    @Column(name = "so_tien", nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Column(name = "phuong_thuc_thanh_toan", length = 20)
    private String paymentMethod = "VNPAY";

    @Column(name = "tham_chieu_giao_dich_vnpay", length = 100)
    private String vnpayTransactionRef;

    @Column(name = "trang_thai", nullable = false, length = 15)
    private String status = "PENDING";

    @Column(name = "thoi_diem_giao_dich", updatable = false)
    private LocalDateTime transactionDate = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_goi_dich_vu")
    private com.rental.modules.subscription.domain.entity.MembershipPackage purchasedPackage;
    @Column(name = "ten_goi_tai_thoi_diem_mua", length = 20)
    private String packageNameSnapshot;
    @Column(name = "han_muc_tin_thuong_khi_mua") private Short standardQuotaSnapshot;
    @Column(name = "han_muc_tin_uu_tien_khi_mua") private Short vipQuotaSnapshot;
    @Column(name = "han_muc_lam_moi_khi_mua") private Short refreshQuotaSnapshot;
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

