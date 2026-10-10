package com.rental.modules.payment.controller;

import com.rental.modules.payment.service.PaymentService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth/test-payment")
public class TestPaymentController {

    private final PaymentService paymentService;

    public TestPaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }


    @GetMapping
    public String testPayment(@RequestParam String email, @RequestParam Short packageId, HttpServletRequest request) {
        try {
            return paymentService.createPaymentUrl(email, packageId, request);
        } catch (Exception e) {
            // Ignore stack trace to avoid SonarLint warning and bypass parser bug
            return "ERROR: " + e.getMessage() + " | " + e.getClass().getName();
        }
    }
}
