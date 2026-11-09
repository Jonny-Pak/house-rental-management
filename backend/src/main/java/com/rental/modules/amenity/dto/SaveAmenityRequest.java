package com.rental.modules.amenity.dto;

import jakarta.validation.constraints.*;

public record SaveAmenityRequest(
    @NotBlank @Size(max = 100) String name,
    @NotNull @Pattern(regexp = "FURNITURE|UTILITY") String category,
    @Size(max = 255) String description,
    @NotNull Boolean active,
    Long version) {}
