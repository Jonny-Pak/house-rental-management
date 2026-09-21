package com.rental.modules.subscription.service;

import com.rental.modules.subscription.entity.MembershipPackage;
import com.rental.modules.subscription.repository.MembershipPackageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MembershipPackageService {

    private final MembershipPackageRepository membershipPackageRepository;

    @Transactional(readOnly = true)
    public List<MembershipPackage> getAllPackages() {
        return membershipPackageRepository.findAll();
    }
}