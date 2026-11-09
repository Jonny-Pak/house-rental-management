package com.rental.modules.chatbot;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

public record SearchPlan(
    @NotNull @Pattern(regexp = "SEARCH|HELP|UNSUPPORTED|RESET") String action,
    @NotNull @Pattern(regexp = "NONE|LOCATION|DETAILS") String clarification,
    @NotNull @Valid ChatFilters filters
) {}
