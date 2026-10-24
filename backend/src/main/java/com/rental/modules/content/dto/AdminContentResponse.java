package com.rental.modules.content.dto;

import com.rental.modules.content.domain.entity.SystemContent;
import java.time.LocalDateTime;
import java.util.Objects;

public record AdminContentResponse(String slug, String title, String body, boolean published,
        boolean hasDraft, LocalDateTime publishedAt, LocalDateTime updatedAt, Long version) {
    public static AdminContentResponse from(SystemContent content) {
        boolean hasDraft = !Objects.equals(content.getTitle(), content.getPublishedTitle())
            || !Objects.equals(content.getBody(), content.getPublishedBody());
        return new AdminContentResponse(content.getSlug(), content.getTitle(), content.getBody(),
            content.isPublished(), hasDraft, content.getPublishedAt(), content.getUpdatedAt(), content.getVersion());
    }
}
