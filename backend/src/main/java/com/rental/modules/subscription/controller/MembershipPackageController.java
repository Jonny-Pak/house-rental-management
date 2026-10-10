package com.rental.modules.subscription.controller;

import com.rental.modules.subscription.entity.MembershipPackage;
import com.rental.modules.subscription.service.MembershipPackageService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/memberships")
public class MembershipPackageController {

    private final MembershipPackageService membershipPackageService;

    public MembershipPackageController(MembershipPackageService membershipPackageService) {
        this.membershipPackageService = membershipPackageService;
    }


    @GetMapping
    public ResponseEntity<List<MembershipPackage>> getAllPackages() {
        return ResponseEntity.ok(membershipPackageService.getAllPackages());
    }
}
