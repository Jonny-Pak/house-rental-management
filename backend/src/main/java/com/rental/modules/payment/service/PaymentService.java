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
        if (membershipPackage.isDefaultPackage()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Gói Cơ bản được cấp tự động khi đăng ký tài khoản, không thể đăng ký lại.");
        }
        if (!membershipPackage.isActive()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT, "Gói dịch vụ đã ngừng bán. Vui lòng tải lại danh sách gói.");
        }

        boolean tierPackage = isPlusOrPro(membershipPackage.getPackageName());
        if (tierPackage) userSubscriptionRepository.findByUser(user).ifPresent(subscription -> {
            boolean active = "ACTIVE".equals(subscription.getStatus())
                    && (subscription.getQuotaResetAt() == null || subscription.getQuotaResetAt().isAfter(LocalDateTime.now()));
            if (active && subscription.getMembershipPackage().getId().equals(packageId)) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT,
                        "Bạn đang sử dụng gói " + subscription.getPackageNameSnapshot() + ". Không thể mua trùng gói này khi gói hiện tại còn hạn.");
            }
        });
        if (tierPackage && paymentTransactionRepository.existsByUser_UserIdAndPurchasedPackage_IdAndStatusAndTransactionDateAfter(
                user.getUserId(), packageId, "PENDING", LocalDateTime.now().minusMinutes(15))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.CONFLICT,
                    "Bạn đang có giao dịch gói này chờ xử lý. Hãy kiểm tra lịch sử thanh toán trước khi tạo giao dịch mới.");
        }

        if (membershipPackage.getPrice().signum() > 0 &&
                (vnPayConfig.getVnp_TmnCode() == null || vnPayConfig.getVnp_TmnCode().isBlank()
                || vnPayConfig.getVnp_HashSecret() == null || vnPayConfig.getVnp_HashSecret().isBlank()
                || vnPayConfig.getVnp_PayUrl() == null || !vnPayConfig.getVnp_PayUrl().startsWith("https://"))) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE,
                    "Chưa cấu hình cổng thanh toán VNPAY. Vui lòng liên hệ quản trị viên.");
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

    private boolean isPlusOrPro(String packageName) {
        String normalized = packageName == null ? "" : packageName.toUpperCase(Locale.ROOT);
        return normalized.contains("PLUS") || normalized.contains("PRO");
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
        vnp_Params.put("vnp_ReturnUrl", returnUrl(request));

        String clientIp = request.getRemoteAddr();
        if (clientIp == null || clientIp.contains(":")) clientIp = "127.0.0.1";
        vnp_Params.put("vnp_IpAddr", clientIp);

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
        String vnp_CreateDate = LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).format(formatter);
        vnp_Params.put("vnp_CreateDate", vnp_CreateDate);

        String vnp_ExpireDate = LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).plusMinutes(15).format(formatter);
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
                    hashData.append(URLEncoder.encode(fieldValue, StandardCharsets.UTF_8.toString()));

                    query.append(URLEncoder.encode(fieldName, StandardCharsets.UTF_8.toString()));
                    query.append('=');
                    query.append(URLEncoder.encode(fieldValue, StandardCharsets.UTF_8.toString()));
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

    private String returnUrl(HttpServletRequest request) {
        String configured = vnPayConfig.getVnp_ReturnUrl();
        if (configured != null && !configured.isBlank()) return configured;
        String origin = request.getScheme() + "://" + request.getServerName();
        if (request.getServerPort() != 80 && request.getServerPort() != 443) origin += ":" + request.getServerPort();
        return origin + "/api/v1/payments/vnpay-return";
    }

    public record PaymentStatus(String reference, String packageName, BigDecimal amount, String status,
            String responseCode, LocalDateTime createdAt) {}

    private record CallbackResult(String code, String message, String status) {}

    @Transactional(readOnly = true)
    public PaymentStatus getStatus(Long userId, String reference) {
        if (reference == null || !reference.matches("[a-zA-Z0-9_-]{1,100}")) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Mã giao dịch không hợp lệ.");
        }
        PaymentTransaction payment = paymentTransactionRepository.findByVnpayTransactionRef(reference).orElseThrow(() ->
                new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND,
                        "Không tìm thấy giao dịch của bạn."));
        if (!payment.getUser().getUserId().equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND,
                    "Không tìm thấy giao dịch của bạn.");
        }
        return toStatus(payment);
    }

    @Transactional(readOnly = true)
    public List<PaymentStatus> history(Long userId) {
        List<PaymentStatus> result = new ArrayList<>();
        for (PaymentTransaction payment : paymentTransactionRepository.findTop20ByUser_UserIdOrderByTransactionDateDescIdDesc(userId)) {
            result.add(toStatus(payment));
        }
        return result;
    }

    private PaymentStatus toStatus(PaymentTransaction payment) {
        String status = payment.getStatus();
        if ("FAILED".equals(status) && "24".equals(payment.getResponseCode())) status = "CANCELLED";
        if ("PENDING".equals(status) && payment.getTransactionDate().plusMinutes(15).isBefore(LocalDateTime.now())) status = "EXPIRED";
        return new PaymentStatus(payment.getVnpayTransactionRef(), payment.getPackageNameSnapshot(), payment.getAmount(),
                status, payment.getResponseCode(), payment.getTransactionDate());
    }

    @Transactional
    public boolean processVnPayReturn(Map<String, String> params) {
        return "SUCCESS".equals(confirmPayment(params).status());
    }

    @Transactional
    public Map<String, String> processIpn(Map<String, String> params) {
        CallbackResult result = confirmPayment(params);
        return Map.of("RspCode", result.code(), "Message", result.message());
    }

    private CallbackResult confirmPayment(Map<String, String> params) {
        if (!validSignature(params) || !Objects.equals(vnPayConfig.getVnp_TmnCode(), params.get("vnp_TmnCode"))) {
            return new CallbackResult("97", "Invalid signature", "INVALID");
        }
        String reference = params.get("vnp_TxnRef");
        if (reference == null || !reference.matches("[a-zA-Z0-9_-]{1,100}")) {
            return new CallbackResult("01", "Order not found", "INVALID");
        }
        PaymentTransaction payment = paymentTransactionRepository.findForUpdate(reference).orElse(null);
        if (payment == null || payment.getPurchasedPackage() == null || payment.getStandardQuotaSnapshot() == null
                || payment.getVipQuotaSnapshot() == null || payment.getRefreshQuotaSnapshot() == null) {
            return new CallbackResult("01", "Order not found", "INVALID");
        }
        String amount = params.get("vnp_Amount");
        if (amount == null || !amount.matches("[0-9]{1,18}")
                || new BigDecimal(amount).compareTo(payment.getAmount().multiply(new BigDecimal(100))) != 0) {
            return new CallbackResult("04", "Invalid amount", "INVALID");
        }
        if (!"PENDING".equals(payment.getStatus())) {
            return new CallbackResult("02", "Order already confirmed", payment.getStatus());
        }
        String responseCode = params.get("vnp_ResponseCode");
        String transactionStatus = params.get("vnp_TransactionStatus");
        if (responseCode == null || !responseCode.matches("[0-9]{2}")
                || transactionStatus == null || !transactionStatus.matches("[0-9]{2}")) {
            return new CallbackResult("99", "Missing payment result", "INVALID");
        }
        if ("00".equals(responseCode) && "00".equals(transactionStatus)) {
            addPackageToUser(payment);
            payment.setStatus("SUCCESS");
        } else {
            payment.setStatus("FAILED");
        }
        payment.setResponseCode(responseCode);
        paymentTransactionRepository.save(payment);
        return new CallbackResult("00", "Confirm success", payment.getStatus());
    }

    private boolean validSignature(Map<String, String> params) {
        String signature = params.get("vnp_SecureHash");
        if (signature == null || !signature.matches("[a-fA-F0-9]{128}")) return false;
        Map<String, String> signed = new TreeMap<>();
        for (var entry : params.entrySet()) {
            if (entry.getKey().startsWith("vnp_") && !entry.getKey().equals("vnp_SecureHash")
                    && !entry.getKey().equals("vnp_SecureHashType") && entry.getValue() != null && !entry.getValue().isEmpty()) {
                signed.put(entry.getKey(), entry.getValue());
            }
        }
        StringBuilder data = new StringBuilder();
        for (var entry : signed.entrySet()) {
            if (!data.isEmpty()) data.append('&');
            data.append(entry.getKey()).append('=').append(URLEncoder.encode(entry.getValue(), StandardCharsets.UTF_8));
        }
        String expected = vnPayConfig.hmacSHA512(vnPayConfig.getVnp_HashSecret(), data.toString());
        return !expected.isEmpty() && java.security.MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.US_ASCII), signature.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.US_ASCII));
    }

    private void addPackageToUser(PaymentTransaction payment) {
        User user = userRepository.findForAdminUpdate(payment.getUser().getUserId()).orElseThrow();
        UserSubscription subscription = userSubscriptionRepository.findByUser(user).orElse(new UserSubscription());
        if (!"ACTIVE".equals(subscription.getStatus()) || (subscription.getQuotaResetAt() != null
                && !subscription.getQuotaResetAt().isAfter(LocalDateTime.now()))) {
            subscription.setRemainingStandardQuota(0);
            subscription.setRemainingVipQuota(0);
            subscription.setRemainingRefreshQuota(0);
        }
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
