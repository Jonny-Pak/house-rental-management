package com.rental.modules.incident.domain.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "incident_updates")
public class IncidentUpdate {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "incident_id", nullable = false)
    private Long incidentId;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "actor_id", nullable = false)
    private User actor;
    @Column(nullable = false, length = 20)
    private String status;
    @Column(nullable = false, length = 2000)
    private String message;
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public IncidentUpdate() {}
    public IncidentUpdate(Long incidentId, User actor, String status, String message, LocalDateTime createdAt) {
        this.incidentId = incidentId;
        this.actor = actor;
        this.status = status;
        this.message = message;
        this.createdAt = createdAt;
    }
    public Long getId() { return id; }
    public User getActor() { return actor; }
    public String getStatus() { return status; }
    public String getMessage() { return message; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
