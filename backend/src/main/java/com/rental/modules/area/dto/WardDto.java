package com.rental.modules.area.dto;


public class WardDto {
    private Long id;
    private String name;
    private String code;
    private Long districtId;

    public WardDto() {}

    public WardDto(Long id, String name, String code, Long districtId) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.districtId = districtId;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public Long getDistrictId() { return districtId; }
    public void setDistrictId(Long districtId) { this.districtId = districtId; }
}
