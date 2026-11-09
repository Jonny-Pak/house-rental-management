package com.rental.modules.chatbot;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

public record ChatRequest(
    @NotBlank @Size(max = 1000) String message,
    @Valid ChatFilters context,
    @DecimalMin("-90") @DecimalMax("90") Double latitude,
    @DecimalMin("-180") @DecimalMax("180") Double longitude,
    @Size(max = 200) String locationName
) {
    public ChatRequest {
        context = context == null ? ChatFilters.empty() : context;
    }
}
