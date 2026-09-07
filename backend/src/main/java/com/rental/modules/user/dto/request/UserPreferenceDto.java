package com.rental.modules.user.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPreferenceDto {
    private Double minBudget;
    private Double maxBudget;
    private Boolean hasPet;
    private String preferredArea;
}
