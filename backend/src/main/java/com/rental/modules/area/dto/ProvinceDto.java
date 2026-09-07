package com.rental.modules.area.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class ProvinceDto {
    private Long id;
    private String name;
    private String code;
}
