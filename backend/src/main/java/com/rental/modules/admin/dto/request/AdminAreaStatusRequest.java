package com.rental.modules.admin.dto.request;

import jakarta.validation.constraints.NotNull;

public record AdminAreaStatusRequest(@NotNull Boolean active) {}
