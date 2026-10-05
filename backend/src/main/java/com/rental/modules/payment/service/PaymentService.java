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
                .paymentMethod("VNPAY")
                .transactionDate(LocalDateTime.now())
                .build();
        
        paymentTransactionRepository.save(transaction);

        long amount = membershipPackage.getPrice().multiply(new BigDecimal(100)).longValue();

        Map<String, String> vnp_Params = new HashMap<>();
        vnp_Params.put("vnp_Version", "2.1.0");
        vnp_Params.put("vnp_Command", "pay");
        vnp_Params.put("vnp_TmnCode", vnPayConfig.getVnp_TmnCode());
        vnp_Params.put("vnp_Amount", String.valueOf(amount));
        vnp_Params.put("vnp_CurrCode", "VND");
        
        // Use vnp_TxnRef as both Bank and Transaction Ref
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
        Iterator<String> itr = fieldNames.iterator();
        while (itr.hasNext()) {
            String fieldName = itr.next();
            String fieldValue = vnp_Params.get(fieldName);
            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                hashData.append(fieldName);
                hashData.append('=');
                hashData.append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII));
                
                query.append(URLEncoder.encode(fieldName, StandardCharsets.US_ASCII));
                query.append('=');
                query.append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII));
                if (itr.hasNext()) {
                    query.append('&');
                    hashData.append('&');
                }
            }
        }
        
        String queryUrl = query.toString();
        String vnp_SecureHash = vnPayConfig.hmacSHA512(vnPayConfig.getVnp_HashSecret(), hashData.toString());
        queryUrl += "&vnp_SecureHash=" + vnp_SecureHash;
        
        return vnPayConfig.getVnp_PayUrl() + "?" + queryUrl;
    }

    @Transactional
    public boolean processVnPayReturn(Map<String, String> fields) {
        String vnp_SecureHash = fields.remove("vnp_SecureHash");
        fields.remove("vnp_SecureHashType");

        List<String> fieldNames = new ArrayList<>(fields.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        Iterator<String> itr = fieldNames.iterator();
        while (itr.hasNext()) {
            String fieldName = itr.next();
            String fieldValue = fields.get(fieldName);
            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                hashData.append(fieldName);
                hashData.append('=');
                hashData.append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII));
                if (itr.hasNext()) {
                    hashData.append('&');
                }
            }
        }
        
        String signValue = vnPayConfig.hmacSHA512(vnPayConfig.getVnp_HashSecret(), hashData.toString());
        if (!signValue.equals(vnp_SecureHash)) {
            return false;
        }

        String txnRef = fields.get("vnp_TxnRef");
        String responseCode = fields.get("vnp_ResponseCode");

        PaymentTransaction transaction = paymentTransactionRepository.findByVnpayTransactionRef(txnRef)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));

        if (!"PENDING".equals(transaction.getStatus())) {
            return "00".equals(responseCode) && "SUCCESS".equals(transaction.getStatus());
        }

        if ("00".equals(responseCode)) {
            transaction.setStatus("SUCCESS");
            
            // Extract packageId from txnRef: packageId_userId_timestamp
            String[] parts = txnRef.split("_");
            Short packageId = Short.parseShort(parts[0]);
            
            MembershipPackage membershipPackage = membershipPackageRepository.findById(packageId)
                    .orElseThrow(() -> new RuntimeException("Package not found"));
            
            User user = transaction.getUser();
            
            UserSubscription subscription = userSubscriptionRepository.findByUser(user).orElse(null);
            
            if (subscription == null) {
                subscription = UserSubscription.builder()
                        .user(user)
                        .membershipPackage(membershipPackage)
                        .remainingStandardQuota(membershipPackage.getStandardPostQuota())
                        .remainingVipQuota(membershipPackage.getVipPostQuota())
                        .remainingRefreshQuota(membershipPackage.getRefreshQuota())
                        .status("ACTIVE")
                        .purchasedAt(LocalDateTime.now())
                        .quotaResetAt(LocalDateTime.now().plusDays(30))
                        .build();
            } else {
                subscription.setMembershipPackage(membershipPackage);
                
                short std = subscription.getRemainingStandardQuota() != null ? subscription.getRemainingStandardQuota() : 0;
                short vip = subscription.getRemainingVipQuota() != null ? subscription.getRemainingVipQuota() : 0;
                short ref = subscription.getRemainingRefreshQuota() != null ? subscription.getRemainingRefreshQuota() : 0;
                
                subscription.setRemainingStandardQuota((short) (std + membershipPackage.getStandardPostQuota()));
                subscription.setRemainingVipQuota((short) (vip + membershipPackage.getVipPostQuota()));
                subscription.setRemainingRefreshQuota((short) (ref + membershipPackage.getRefreshQuota()));
                subscription.setStatus("ACTIVE");
                subscription.setQuotaResetAt(LocalDateTime.now().plusDays(30));
                subscription.setPurchasedAt(LocalDateTime.now());
            }
            
            userSubscriptionRepository.save(subscription);
            transaction.setSubscription(subscription);
            paymentTransactionRepository.save(transaction);
            
            return true;
        } else {
            transaction.setStatus("FAILED");
            paymentTransactionRepository.save(transaction);
            return false;
        }
    }
}
