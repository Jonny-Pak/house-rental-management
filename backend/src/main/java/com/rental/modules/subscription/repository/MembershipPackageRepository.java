package com.rental.modules.subscription.repository;

import com.rental.modules.subscription.entity.MembershipPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MembershipPackageRepository extends JpaRepository<MembershipPackage, Short> {
}