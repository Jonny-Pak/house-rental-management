package com.rental.modules.admin.dto.request;

import jakarta.validation.constraints.*;

public record AdminAreaRequest(
    @NotBlank @Size(max = 150) String name,
    @NotBlank @Pattern(regexp = "PROVINCE|DISTRICT|WARD|COMMUNE|SPECIAL") String type,
    @NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{1,20}") String code,
    @Positive Long parentId
) {}
