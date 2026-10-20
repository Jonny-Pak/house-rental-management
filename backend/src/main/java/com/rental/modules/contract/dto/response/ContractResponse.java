package com.rental.modules.contract.dto.response;
import com.rental.modules.contract.dto.request.ContractDetails;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
public record ContractResponse(Long id, Long listingId, String listingName, String address,
    Long landlordId, String landlordName, Long tenantId, String tenantName,
    LocalDate startDate, LocalDate endDate, BigDecimal monthlyRent, BigDecimal depositAmount,
    String status, String note, LocalDateTime createdAt, String myRole, Long version,
    String contractType, ContractDetails details, String documentText, LocalDateTime acceptedAt) {}
