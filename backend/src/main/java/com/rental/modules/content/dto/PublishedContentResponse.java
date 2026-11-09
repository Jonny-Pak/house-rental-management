package com.rental.modules.content.dto;

import java.time.LocalDateTime;

public record PublishedContentResponse(String slug, String title, String body, LocalDateTime publishedAt) {}
