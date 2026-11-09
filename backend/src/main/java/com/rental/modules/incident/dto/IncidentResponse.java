package com.rental.modules.incident.dto;
import java.time.LocalDateTime;
import java.util.List;
public record IncidentResponse(Long id, String title, String category, String description, String status,
    Long reporterId, String reporterName, String reporterEmail,
    LocalDateTime createdAt, LocalDateTime updatedAt, Long version, List<Update> history) {
    public record Update(Long id, String actorName, String status, String message, LocalDateTime createdAt) {}
}
