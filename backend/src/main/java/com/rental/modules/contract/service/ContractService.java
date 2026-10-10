package com.rental.modules.contract.service;

import com.rental.modules.contract.dto.request.CreateContractRequest;
import com.rental.modules.contract.entity.Contract;
import com.rental.modules.contract.repository.ContractRepository;
import com.rental.modules.listing.entity.Listing;
import com.rental.modules.listing.repository.ListingRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ContractService {

    private final ContractRepository contractRepository;
    private final UserRepository userRepository;
    private final ListingRepository listingRepository;

    public ContractService(ContractRepository contractRepository, UserRepository userRepository, ListingRepository listingRepository) {
        this.contractRepository = contractRepository;
        this.userRepository = userRepository;
        this.listingRepository = listingRepository;
    }

    @Transactional
    public Contract createContract(String landlordEmail, CreateContractRequest request) {
        User landlord = userRepository.findByEmail(landlordEmail)
                .orElseThrow(() -> new RuntimeException("Landlord not found"));

        User tenant = userRepository.findById(request.getTenantId())
                .orElseThrow(() -> new RuntimeException("Tenant not found"));

        Listing listing = listingRepository.findById(request.getListingId())
                .orElseThrow(() -> new RuntimeException("Listing not found"));

        Contract contract = new Contract(
                listing,
                landlord,
                tenant,
                request.getStartDate(),
                request.getEndDate(),
                request.getMonthlyRent(),
                request.getDepositAmount(),
                "ACTIVE",
                null, // contractFileUrl is not in builder
                LocalDateTime.now()
        );

        return contractRepository.save(contract);
    }

    @Transactional(readOnly = true)
    public List<Contract> getMyContracts(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
                
        return contractRepository.findByLandlordOrTenant(user, user);
    }
}
