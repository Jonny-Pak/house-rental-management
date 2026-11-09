package com.rental.modules.admin.dto.response;

public record AdminAreaResponse(Long id, String name, String type, String code,
    Long parentId, String parentName, boolean active, long children,
    long listingCount, long propertyCount) {}
