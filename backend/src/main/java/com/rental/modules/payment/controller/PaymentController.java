package com.rental.modules.payment.controller;

import com.rental.modules.payment.service.PaymentService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.view.RedirectView;

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

    @GetMapping("/vnpay-return")
    public RedirectView vnpayReturn(@RequestParam Map<String, String> allParams) {
        boolean success = paymentService.processVnPayReturn(allParams);

        String redirectUrl = "myapp://payment-result?status=failed";
        if (success) {
            redirectUrl = "myapp://payment-result?status=success";
        }

        return new RedirectView(redirectUrl);
    }
}
