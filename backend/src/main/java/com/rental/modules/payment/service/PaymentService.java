package com.rental.modules.payment.service;

import com.rental.modules.payment.config.VnPayConfig;
import com.rental.modules.payment.domain.entity.PaymentTransaction;
import com.rental.modules.payment.repository.PaymentTransactionRepository;
import com.rental.modules.subscription.domain.entity.MembershipPackage;
import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.subscription.repository.MembershipPackageRepository;
import com.rental.modules.subscription.repository.UserSubscriptionRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class PaymentService {

    private final VnPayConfig vnPayConfig;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final UserRepository userRepository;
    private final MembershipPackageRepository membershipPackageRepository;
    private final UserSubscriptionRepository userSubscriptionRepository;

    public PaymentService(VnPayConfig vnPayConfig, PaymentTransactionRepository paymentTransactionRepository, UserRepository userRepository, MembershipPackageRepository membershipPackageRepository, UserSubscriptionRepository userSubscriptionRepository) {
        this.vnPayConfig = vnPayConfig;
        this.paymentTransactionRepository = paymentTransactionRepository;
        this.userRepository = userRepository;
        this.membershipPackageRepository = membershipPackageRepository;
        this.userSubscriptionRepository = userSubscriptionRepository;
    }

    @Transactional
    public String createPaymentUrl(String userEmail, Short packageId, HttpServletRequest request) {
        java.util.Optional<User> userResult = userRepository.findByEmail(userEmail);
        if (userResult.isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản.");
        }
        User user = userRepository.findForAdminUpdate(userResult.get().getUserId()).orElseThrow();

        java.util.Optional<MembershipPackage> membershipPackageResult = membershipPackageRepository.findForUpdate(packageId);
        if (membershipPackageResult.isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Gói dịch vụ không còn tồn tại. Vui lòng tải lại danh sách.");
        }
        MembershipPackage membershipPackage = membershipPackageResult.get();
        if (!membershipPackage.isActive()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT, "Gói dịch vụ đã ngừng bán. Vui lòng tải lại danh sách gói.");
        }

        String vnp_TxnRef = packageId + "_" + user.getUserId() + "_" + UUID.randomUUID();

        PaymentTransaction transaction = new PaymentTransaction();
        transaction.setUser(user);
        transaction.setPurchasedPackage(membershipPackage);
        transaction.setPackageNameSnapshot(membershipPackage.getPackageName());
        transaction.setStandardQuotaSnapshot(membershipPackage.getStandardPostQuota());
        transaction.setVipQuotaSnapshot(membershipPackage.getVipPostQuota());
        transaction.setRefreshQuotaSnapshot(membershipPackage.getRefreshQuota());
        transaction.setAmount(membershipPackage.getPrice());
        transaction.setVnpayTransactionRef(vnp_TxnRef);
        transaction.setStatus("PENDING");
        if (membershipPackage.getPrice().compareTo(BigDecimal.ZERO) == 0) {
            transaction.setPaymentMethod("FREE");
        } else {
            transaction.setPaymentMethod("VNPAY");
        }
        transaction.setTransactionDate(LocalDateTime.now());

        paymentTransactionRepository.save(transaction);

        long amount = membershipPackage.getPrice().multiply(new BigDecimal(100)).longValue();

        if (amount == 0) {

            transaction.setStatus("SUCCESS");
            paymentTransactionRepository.save(transaction);

            addPackageToUser(transaction);

            return "FREE_SUCCESS";
        }

        return buildVnPayUrl(user, packageId, vnp_TxnRef, amount, request);
    }

    private String buildVnPayUrl(User user, Short packageId, String vnp_TxnRef,
            long amount, HttpServletRequest request) {
        Map<String, String> vnp_Params = new HashMap<>();
        vnp_Params.put("vnp_Version", "2.1.0");
        vnp_Params.put("vnp_Command", "pay");
        vnp_Params.put("vnp_TmnCode", vnPayConfig.getVnp_TmnCode());
        vnp_Params.put("vnp_Amount", String.valueOf(amount));
        vnp_Params.put("vnp_CurrCode", "VND");

        vnp_Params.put("vnp_TxnRef", vnp_TxnRef);
        vnp_Params.put("vnp_OrderInfo", "Payment for Package ID " + packageId + " by User " + user.getUserId());
        vnp_Params.put("vnp_OrderType", "other");
        vnp_Params.put("vnp_Locale", "vn");
        vnp_Params.put("vnp_ReturnUrl", vnPayConfig.getVnp_ReturnUrl());

        String clientIp = request.getHeader("X-FORWARDED-FOR");
        if (clientIp == null || clientIp.isEmpty()) {
            clientIp = request.getRemoteAddr();
        }
        vnp_Params.put("vnp_IpAddr", clientIp);

        Calendar cld = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
        String vnp_CreateDate = LocalDateTime.now().format(formatter);
        vnp_Params.put("vnp_CreateDate", vnp_CreateDate);

        cld.add(Calendar.MINUTE, 15);
        String vnp_ExpireDate = LocalDateTime.now().plusMinutes(15).format(formatter);
        vnp_Params.put("vnp_ExpireDate", vnp_ExpireDate);

        List<String> fieldNames = new ArrayList<>(vnp_Params.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();
        try {
            Iterator<String> itr = fieldNames.iterator();
            while (itr.hasNext()) {
                String fieldName = itr.next();
                String fieldValue = vnp_Params.get(fieldName);
                if ((fieldValue != null) && (fieldValue.length() > 0)) {
                    hashData.append(fieldName);
                    hashData.append('=');
                    hashData.append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));

                    query.append(URLEncoder.encode(fieldName, StandardCharsets.US_ASCII.toString()));
                    query.append('=');
                    query.append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));
                    if (itr.hasNext()) {
                        query.append('&');
                        hashData.append('&');
                    }
                }
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        String queryUrl = query.toString();
        String vnp_SecureHash = vnPayConfig.hmacSHA512(vnPayConfig.getVnp_HashSecret(), hashData.toString());
        queryUrl += "&vnp_SecureHash=" + vnp_SecureHash;

        return vnPayConfig.getVnp_PayUrl() + "?" + queryUrl;
    }

    @Transactional
    public boolean processVnPayReturn(Map<String, String> vnpayParams) {
        vnpayParams = new HashMap<>(vnpayParams);
        String vnp_SecureHash = vnpayParams.get("vnp_SecureHash");
        vnpayParams.remove("vnp_SecureHash");
        vnpayParams.remove("vnp_SecureHashType");

        List<String> fieldNames = new ArrayList<>(vnpayParams.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        try {
            Iterator<String> itr = fieldNames.iterator();
            while (itr.hasNext()) {
                String fieldName = itr.next();
                String fieldValue = vnpayParams.get(fieldName);
                if ((fieldValue != null) && (fieldValue.length() > 0)) {
                    hashData.append(fieldName);
                    hashData.append('=');
                    hashData.append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));
                    if (itr.hasNext()) {
                        hashData.append('&');
                    }
                }
            }
        } catch (Exception e) {
            return false;
        }

        String signValue = vnPayConfig.hmacSHA512(vnPayConfig.getVnp_HashSecret(), hashData.toString());
        if (signValue.isEmpty() || !signValue.equals(vnp_SecureHash)) {
            return false;
        }

        String vnp_TxnRef = vnpayParams.get("vnp_TxnRef");
        PaymentTransaction transaction = paymentTransactionRepository.findForUpdate(vnp_TxnRef).orElse(null);
        if (transaction == null || transaction.getPurchasedPackage() == null || transaction.getStandardQuotaSnapshot() == null
            || transaction.getVipQuotaSnapshot() == null || transaction.getRefreshQuotaSnapshot() == null) return false;
        String paidAmount = vnpayParams.get("vnp_Amount");
        if (paidAmount == null || !paidAmount.matches("[0-9]{1,18}")
            || new BigDecimal(paidAmount).compareTo(transaction.getAmount().multiply(new BigDecimal(100))) != 0) return false;
        if ("SUCCESS".equals(transaction.getStatus())) return true;
        if (!"PENDING".equals(transaction.getStatus())) return false;
        if ("00".equals(vnpayParams.get("vnp_ResponseCode"))
            && (vnpayParams.get("vnp_TransactionStatus") == null || "00".equals(vnpayParams.get("vnp_TransactionStatus")))) {
            addPackageToUser(transaction);
            transaction.setStatus("SUCCESS");
            paymentTransactionRepository.save(transaction);
            return true;
        }
        transaction.setStatus("FAILED");
        paymentTransactionRepository.save(transaction);
        return false;
    }

    private void addPackageToUser(PaymentTransaction payment) {
        User user = userRepository.findForAdminUpdate(payment.getUser().getUserId()).orElseThrow();
        UserSubscription subscription = userSubscriptionRepository.findByUser(user).orElse(new UserSubscription());
        subscription.setUser(user);
        subscription.setMembershipPackage(payment.getPurchasedPackage());
        subscription.setPackageNameSnapshot(payment.getPackageNameSnapshot());
        subscription.setPurchasedAt(LocalDateTime.now());
        subscription.setRemainingStandardQuota(addQuota(subscription.getRemainingStandardQuota(), payment.getStandardQuotaSnapshot()));
        subscription.setRemainingVipQuota(addQuota(subscription.getRemainingVipQuota(), payment.getVipQuotaSnapshot()));
        subscription.setRemainingRefreshQuota(addQuota(subscription.getRemainingRefreshQuota(), payment.getRefreshQuotaSnapshot()));
        subscription.setStatus("ACTIVE");
        subscription.setQuotaResetAt(LocalDateTime.now().plusDays(30));
        userSubscriptionRepository.save(subscription);
    }

    private int addQuota(Integer remaining, Short purchased) {
        int current = remaining == null ? 0 : remaining;
        int extra = purchased == null ? 0 : purchased;
        return Math.addExact(current, extra);
    }
}
