package com.rental.modules.contract.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

public class CreateContractRequest {
    @jakarta.validation.constraints.NotNull @jakarta.validation.constraints.Positive
    private Long listingId;
    @jakarta.validation.constraints.NotNull @jakarta.validation.constraints.Positive
    private Long tenantId;
    @jakarta.validation.constraints.NotNull
    private LocalDate startDate;
    @jakarta.validation.constraints.NotNull
    private LocalDate endDate;
    @jakarta.validation.constraints.NotNull @jakarta.validation.constraints.DecimalMin("1") @jakarta.validation.constraints.Digits(integer=10, fraction=2)
    private BigDecimal monthlyRent;
    @jakarta.validation.constraints.NotNull @jakarta.validation.constraints.DecimalMin("0") @jakarta.validation.constraints.Digits(integer=10, fraction=2)
    private BigDecimal depositAmount;

    @jakarta.validation.constraints.Size(max=2000)
    private String note;
    public String getNote() {
        return note;
    }
    public void setNote(String value) { note=value; }

    public CreateContractRequest() {}

    public CreateContractRequest(Long listingId, Long tenantId, LocalDate startDate, LocalDate endDate, BigDecimal monthlyRent, BigDecimal depositAmount) {
        this.listingId = listingId;
        this.tenantId = tenantId;
        this.startDate = startDate;
        this.endDate = endDate;
        this.monthlyRent = monthlyRent;
        this.depositAmount = depositAmount;
    }

    public Long getListingId() {
        return listingId;
    }
    public void setListingId(Long listingId) {
        this.listingId = listingId;
    }

    public Long getTenantId() {
        return tenantId;
    }
    public void setTenantId(Long tenantId) {
        this.tenantId = tenantId;
    }

    public LocalDate getStartDate() {
        return startDate;
    }
    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }
    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public BigDecimal getMonthlyRent() {
        return monthlyRent;
    }
    public void setMonthlyRent(BigDecimal monthlyRent) {
        this.monthlyRent = monthlyRent;
    }

    public BigDecimal getDepositAmount() {
        return depositAmount;
    }
    public void setDepositAmount(BigDecimal depositAmount) {
        this.depositAmount = depositAmount;
    }
}
