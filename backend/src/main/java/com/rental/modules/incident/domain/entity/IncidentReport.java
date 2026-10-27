package com.rental.modules.incident.domain.entity;

import com.rental.modules.user.domain.entity.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "incident_reports")
public class IncidentReport {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reporter_id", nullable = false)
    private User reporter;
    @Column(name = "request_key", nullable = false, length = 80)
    private String requestKey;
    @Column(nullable = false, length = 150)
    private String title;
    @Column(nullable = false, length = 20)
    private String category;
    @Column(nullable = false, length = 5000)
    private String description;
    @Column(nullable = false, length = 20)
    private String status = "OPEN";
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    @Version private Long version;

    public Long getId() { return id; }
    public User getReporter() { return reporter; }
    public void setReporter(User value) { reporter = value; }
    public String getRequestKey() { return requestKey; }
    public void setRequestKey(String value) { requestKey = value; }
    public String getTitle() { return title; }
    public void setTitle(String value) { title = value; }
    public String getCategory() { return category; }
    public void setCategory(String value) { category = value; }
    public String getDescription() { return description; }
    public void setDescription(String value) { description = value; }
    public String getStatus() { return status; }
    public void setStatus(String value) { status = value; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime value) { createdAt = value; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime value) { updatedAt = value; }
    public Long getVersion() { return version; }
}
