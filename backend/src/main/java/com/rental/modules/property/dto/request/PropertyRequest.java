package com.rental.modules.property.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class PropertyRequest {

    @NotBlank(message = "Tên khu trọ không được để trống")
    private String name;

    private String description;

    @NotBlank(message = "Địa chỉ không được để trống")
    private String address;

    @NotNull(message = "Tỉnh/Thành phố không được để trống")
    private Long provinceId;

    @NotNull(message = "Quận/Huyện không được để trống")
    private Long districtId;

    @NotNull(message = "Phường/Xã không được để trống")
    private Long wardId;

    private BigDecimal electricityPrice;
    private BigDecimal waterPrice;

    private List<String> imageUrls;
}
