package com.rental.modules.content.dto;

import jakarta.validation.constraints.*;

public record ContentRequest(
    @NotBlank @Size(max = 150) String title,
    @NotBlank @Size(max = 20000) String body,
    @NotNull @Min(0) Long version
) {}
