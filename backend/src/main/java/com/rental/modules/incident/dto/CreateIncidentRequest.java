package com.rental.modules.incident.dto;
import jakarta.validation.constraints.*;
public record CreateIncidentRequest(
    @NotBlank @Pattern(regexp = "[a-zA-Z0-9-]{1,80}") String requestKey,
    @NotBlank @Size(max = 150) String title,
    @NotBlank @Pattern(regexp = "ACCOUNT|LISTING|CONTRACT|PAYMENT|TECHNICAL|OTHER") String category,
    @NotBlank @Size(max = 5000) String description) {}
