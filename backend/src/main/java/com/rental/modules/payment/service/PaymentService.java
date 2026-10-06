package com.rental.modules.payment.service;

import com.rental.modules.payment.config.VnPayConfig;
import com.rental.modules.payment.entity.PaymentTransaction;
import com.rental.modules.payment.repository.PaymentTransactionRepository;
import com.rental.modules.subscription.entity.MembershipPackage;
import com.rental.modules.subscription.entity.UserSubscription;
import com.rental.modules.subscription.repository.MembershipPackageRepository;
import com.rental.modules.subscription.repository.UserSubscriptionRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PaymentService {

    private final VnPayConfig vnPayConfig;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final UserRepository userRepository;
    private final MembershipPackageRepository membershipPackageRepository;
    private final UserSubscriptionRepository userSubscriptionRepository;

    @Transactional
    public String createPaymentUrl(String userEmail, Short packageId, HttpServletRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
                
        MembershipPackage membershipPackage = membershipPackageRepository.findById(packageId)
                .orElseThrow(() -> new RuntimeException("Membership package not found"));

        // Format: pkgId_userId_timestamp
        String vnp_TxnRef = packageId + "_" + user.getUserId() + "_" + System.currentTimeMillis();

        PaymentTransaction transaction = PaymentTransaction.builder()
                .user(user)
                .amount(membershipPackage.getPrice())
                .vnpayTransactionRef(vnp_TxnRef)
                .status("PENDING")
                .paymentMethod(membershipPackage.getPrice().compareTo(BigDecimal.ZERO) == 0 ? "FREE" : "VNPAY")
                .transactionDate(LocalDateTime.now())
                .build();
        
        paymentTransactionRepository.save(transaction);

        long amount = membershipPackage.getPrice().multiply(new BigDecimal(100)).longValue();

        if (amount == 0) {
            // Free package, grant immediately
            transaction.setStatus("SUCCESS");
            paymentTransactionRepository.save(transaction);
            
            UserSubscription subscription = userSubscriptionRepository.findByUser(user)
                    .orElse(new UserSubscription());
            subscription.setUser(user);
            subscription.setMembershipPackage(membershipPackage);
            subscription.setPurchasedAt(LocalDateTime.now());
            subscription.setRemainingStandardQuota(
                    (subscription.getRemainingStandardQuota() != null ? subscription.getRemainingStandardQuota() : 0)
                            + membershipPackage.getStandardPostQuota());
            subscription.setRemainingVipQuota(
                    (subscription.getRemainingVipQuota() != null ? subscription.getRemainingVipQuota() : 0)
                            + membershipPackage.getVipPostQuota());
            subscription.setRemainingRefreshQuota(
                    (subscription.getRemainingRefreshQuota() != null ? subscription.getRemainingRefreshQuota() : 0)
                            + membershipPackage.getRefreshQuota());
            subscription.setStatus("ACTIVE");
            subscription.setQuotaResetAt(LocalDateTime.now().plusDays(30));
            userSubscriptionRepository.save(subscription);

            return "FREE_SUCCESS";
        }

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
        if (!signValue.equals(vnp_SecureHash)) {
            return false;
        }

        String vnp_TxnRef = vnpayParams.get("vnp_TxnRef");
        PaymentTransaction transaction = paymentTransactionRepository.findByVnpayTransactionRef(vnp_TxnRef)
                .orElse(null);

        if (transaction == null) {
            return false;
        }

        String responseCode = vnpayParams.get("vnp_ResponseCode");
        if ("00".equals(responseCode)) {
            transaction.setStatus("SUCCESS");
            paymentTransactionRepository.save(transaction);
            
            String[] parts = vnp_TxnRef.split("_");
            if (parts.length >= 2) {
                Short packageId = Short.parseShort(parts[0]);
                MembershipPackage pkg = membershipPackageRepository.findById(packageId).orElse(null);
                if (pkg != null) {
                    UserSubscription subscription = userSubscriptionRepository.findByUser(transaction.getUser())
                            .orElse(new UserSubscription());
                    subscription.setUser(transaction.getUser());
                    subscription.setMembershipPackage(pkg);
                    subscription.setPurchasedAt(LocalDateTime.now());
                    
                    subscription.setRemainingStandardQuota(
                            (subscription.getRemainingStandardQuota() != null ? subscription.getRemainingStandardQuota() : 0)
                                    + pkg.getStandardPostQuota());
                    subscription.setRemainingVipQuota(
                            (subscription.getRemainingVipQuota() != null ? subscription.getRemainingVipQuota() : 0)
                                    + pkg.getVipPostQuota());
                    subscription.setRemainingRefreshQuota(
                            (subscription.getRemainingRefreshQuota() != null ? subscription.getRemainingRefreshQuota() : 0)
                                    + pkg.getRefreshQuota());
                                    
                    subscription.setStatus("ACTIVE");
                    subscription.setQuotaResetAt(LocalDateTime.now().plusDays(30));
                    userSubscriptionRepository.save(subscription);
                }
            }
            return true;
        } else {
            transaction.setStatus("FAILED");
            paymentTransactionRepository.save(transaction);
            return false;
        }
    }
}
