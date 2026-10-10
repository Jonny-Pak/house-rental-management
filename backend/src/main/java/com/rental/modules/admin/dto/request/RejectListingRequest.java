package com.rental.modules.admin.dto.request;

import jakarta.validation.constraints.NotBlank;

public class RejectListingRequest {

    @NotBlank(message = "Rejection reason must not be blank")
    private String reason;

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}

