package com.rental.modules.area.dto;


public class DistrictDto {
    private Long id;
    private String name;
    private String code;
    private Long provinceId;

    public DistrictDto() {}

    public DistrictDto(Long id, String name, String code, Long provinceId) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.provinceId = provinceId;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public Long getProvinceId() { return provinceId; }
    public void setProvinceId(Long provinceId) { this.provinceId = provinceId; }
}
