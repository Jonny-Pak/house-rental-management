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


    @PostMapping("/create")
    @SuppressWarnings("all")
    public ResponseEntity<Map<String, String>> createPayment(
            @AuthenticationPrincipal org.springframework.security.core.userdetails.UserDetails userDetails,
            @RequestBody Map<String, Object> requestBody,
            HttpServletRequest request) {
        
        // Safely parse packageId to avoid ClassCastException
        Object packageIdObj = requestBody.get("packageId");
        Short packageId = null;
        if (packageIdObj instanceof Number) {
            packageId = ((Number) packageIdObj).shortValue();
        } else if (packageIdObj instanceof String) {
            packageId = Short.valueOf((String) packageIdObj);
        } else {
            throw new IllegalArgumentException("Invalid packageId");
        }

        String paymentUrl = paymentService.createPaymentUrl(userDetails.getUsername(), packageId, request);
        return ResponseEntity.ok(Map.of("paymentUrl", paymentUrl));
    }

    @GetMapping("/vnpay-return")
    public RedirectView vnpayReturn(@RequestParam Map<String, String> allParams) {
        boolean success = paymentService.processVnPayReturn(allParams);
        
        String redirectUrl = success 
                ? "myapp://payment-result?status=success" 
                : "myapp://payment-result?status=failed";
                
        return new RedirectView(redirectUrl);
    }
}
