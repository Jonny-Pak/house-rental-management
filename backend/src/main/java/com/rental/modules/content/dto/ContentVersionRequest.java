package com.rental.modules.content.dto;

import jakarta.validation.constraints.*;

public record ContentVersionRequest(@NotNull @Min(0) Long version) {}
