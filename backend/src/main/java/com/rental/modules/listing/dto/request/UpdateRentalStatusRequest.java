package com.rental.modules.listing.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class UpdateRentalStatusRequest {
    @NotBlank
    @Pattern(regexp = "AVAILABLE|RENTED|HIDDEN")
    private String rentalStatus;
    public String getRentalStatus() {
        return rentalStatus;
    }
    public void setRentalStatus(String rentalStatus) {
        this.rentalStatus = rentalStatus;
    }
}
