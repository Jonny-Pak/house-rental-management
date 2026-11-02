package com.rental.modules.payment.controller;

import com.rental.modules.payment.service.PaymentService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import com.rental.core.security.CustomUserDetails;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    public record CreatePaymentRequest(@jakarta.validation.constraints.NotNull @jakarta.validation.constraints.Min(1) @jakarta.validation.constraints.Max(32767) Integer packageId) {}
    @PostMapping("/create")
    public ResponseEntity<Map<String, String>> createPayment(
        @AuthenticationPrincipal org.springframework.security.core.userdetails.UserDetails userDetails,
        @jakarta.validation.Valid @RequestBody CreatePaymentRequest body, HttpServletRequest request) {
        String paymentUrl = paymentService.createPaymentUrl(userDetails.getUsername(), body.packageId().shortValue(), request);
        return ResponseEntity.ok(Map.of("paymentUrl", paymentUrl));
    }

    @GetMapping("/me")
    public ResponseEntity<java.util.List<PaymentService.PaymentStatus>> history(@AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(paymentService.history(user.getUser().getUserId()));
    }

    @GetMapping("/{reference}/status")
    public ResponseEntity<PaymentService.PaymentStatus> status(@PathVariable String reference,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(paymentService.getStatus(user.getUser().getUserId(), reference));
    }

    @GetMapping("/vnpay-ipn")
    public Map<String, String> ipn(@RequestParam Map<String, String> allParams) {
        try {
            return paymentService.processIpn(allParams);
        } catch (RuntimeException error) {
            return Map.of("RspCode", "99", "Message", "Please retry notification");
        }
    }

    @GetMapping(value = "/vnpay-return", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> vnpayReturn(@RequestParam Map<String, String> allParams) {
        boolean success = paymentService.processVnPayReturn(allParams);
        String reference = allParams.getOrDefault("vnp_TxnRef", "");
        if (!reference.matches("[a-zA-Z0-9_-]{1,100}")) reference = "";
        String appUrl = "houserental://payments/payment-result?reference=" + reference;
        String title = success ? "Thanh toán thành công" : "Kiểm tra kết quả thanh toán";
        String page = """
            <!doctype html><html lang="vi"><head><meta charset="utf-8">
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <title>Kết quả VNPAY</title><style>
            body{font:16px system-ui;background:#edf8f0;color:#173b2b;display:grid;place-items:center;min-height:90vh;margin:20px}
            main{background:white;border-radius:20px;padding:28px;max-width:420px;text-align:center}
            a{display:inline-block;background:#15803d;color:white;text-decoration:none;padding:14px 24px;border-radius:12px}
            p{line-height:1.6}</style></head><body><main><h1>%s</h1>
            <p>Mở ứng dụng để xem trạng thái giao dịch và quyền lợi gói dịch vụ.
            Nếu ứng dụng chưa mở, hãy bấm nút bên dưới hoặc quay lại app và chọn Kiểm tra lại.</p>
            <a href="%s">Mở ứng dụng</a></main></body></html>
            """.formatted(title, appUrl);
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .contentType(new MediaType("text", "html", java.nio.charset.StandardCharsets.UTF_8)).body(page);
    }
}
