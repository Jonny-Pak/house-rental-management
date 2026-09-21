package com.rental.modules.contract.controller;

import com.rental.modules.contract.dto.request.CreateContractRequest;
import com.rental.modules.contract.entity.Contract;
import com.rental.modules.contract.service.ContractService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/contracts")
@RequiredArgsConstructor
public class ContractController {

    private final ContractService contractService;

    @PostMapping
    public ResponseEntity<Contract> createContract(
            @RequestBody CreateContractRequest request,
            Principal principal) {
        String userEmail = principal.getName();
        Contract contract = contractService.createContract(userEmail, request);
        return ResponseEntity.ok(contract);
    }

    @GetMapping("/me")
    public ResponseEntity<List<Contract>> getMyContracts(Principal principal) {
        String userEmail = principal.getName();
        return ResponseEntity.ok(contractService.getMyContracts(userEmail));
    }
}