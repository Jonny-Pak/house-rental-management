package com.rental.modules.incident.dto;
import jakarta.validation.constraints.*;
public record UpdateIncidentRequest(
    @NotBlank @Pattern(regexp = "IN_PROGRESS|RESOLVED|REJECTED") String status,
    @NotBlank @Size(max = 2000) String message,
    @NotNull @Min(0) Long version) {}
