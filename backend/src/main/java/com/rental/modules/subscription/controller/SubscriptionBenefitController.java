package com.rental.modules.subscription.controller;

import com.rental.core.security.CustomUserDetails;
import com.rental.modules.subscription.service.SubscriptionBenefitService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/memberships/me")
public class SubscriptionBenefitController {
    private final SubscriptionBenefitService benefits;

    public SubscriptionBenefitController(SubscriptionBenefitService benefits) {
        this.benefits = benefits;
    }

    @GetMapping
    public SubscriptionBenefitService.Benefits get(@AuthenticationPrincipal CustomUserDetails user) {
        return benefits.getBenefits(user.getUser().getUserId());
    }
}
