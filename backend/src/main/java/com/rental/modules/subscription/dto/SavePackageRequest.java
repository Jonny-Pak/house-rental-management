package com.rental.modules.subscription.dto;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
public record SavePackageRequest(
    @NotBlank @Size(max = 20) String packageName,
    @NotNull @DecimalMin("0") @Digits(integer = 8, fraction = 0) BigDecimal price,
    @NotNull @Min(0) @Max(32767) Integer standardPostQuota,
    @NotNull @Min(0) @Max(32767) Integer vipPostQuota,
    @NotNull @Min(0) @Max(32767) Integer refreshQuota,
    @Size(max = 255) String description,
    @NotNull Boolean active,
    @Min(0) Long version) {}
