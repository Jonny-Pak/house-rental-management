package com.rental.modules.contract.service;

import com.rental.modules.contract.dto.request.CreateContractRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class ContractExcelWriter {
    private final ContractService contracts;
    public ContractExcelWriter(ContractService contracts) { this.contracts = contracts; }

    @Transactional
    public void importAll(String email, List<CreateContractRequest> requests) {
        for (CreateContractRequest request : requests) contracts.createContract(email, request);
    }
}
