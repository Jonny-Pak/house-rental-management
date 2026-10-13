package com.rental.modules.contract.controller;

import com.rental.modules.contract.dto.request.CreateContractRequest;
import com.rental.modules.contract.dto.response.ContractResponse;
import com.rental.modules.contract.service.ContractService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/contracts")
public class ContractController {
    private final ContractService contractService;

    public ContractController(ContractService contractService) {
        this.contractService = contractService;
    }

    @PostMapping
    public ResponseEntity<ContractResponse> createContract(
            @Valid @RequestBody CreateContractRequest request, Principal principal) {
        String email = principal.getName();
        ContractResponse contract = contractService.createContract(email, request);
        return ResponseEntity.status(201).body(contract);
    }

    @GetMapping("/me")
    public List<ContractResponse> getMyContracts(Principal principal) {
        return contractService.getMyContracts(principal.getName());
    }

    @GetMapping("/{id}")
    public ContractResponse getContract(@PathVariable Long id, Principal principal) {
        return contractService.getContract(principal.getName(), id);
    }

    @GetMapping("/tenant")
    public Map<String, Object> findTenant(
            @RequestParam(required = false) String email, @RequestParam(required = false) String phone,
            @RequestParam Long listingId, Principal principal) {
        return contractService.findTenant(principal.getName(), email, phone, listingId);
    }

    @PutMapping("/{id}")
    public ContractResponse updateContract(
            @PathVariable Long id, @Valid @RequestBody CreateContractRequest request, Principal principal) {
        return contractService.updateContract(principal.getName(), id, request);
    }

    public record StatusRequest(
            @NotBlank @Pattern(regexp = "ACTIVE|CANCELLED|TERMINATED") String status,
            @NotNull Long version) {}

    @PatchMapping("/{id}/status")
    public ContractResponse changeStatus(
            @PathVariable Long id, @Valid @RequestBody StatusRequest request, Principal principal) {
        return contractService.changeStatus(principal.getName(), id, request.status(), request.version());
    }
}
