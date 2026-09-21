package com.rental.modules.contract.repository;

import com.rental.modules.contract.entity.Contract;
import com.rental.modules.user.domain.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContractRepository extends JpaRepository<Contract, Long> {
    List<Contract> findByLandlordOrTenant(User landlord, User tenant);
}