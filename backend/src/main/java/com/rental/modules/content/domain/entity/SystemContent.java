package com.rental.modules.content.domain.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "system_contents")
public class SystemContent {
    @Id
    @Column(length = 20)
    private String slug;
    @Column(nullable = false, length = 150)
    private String title;
    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;
    @Column(name = "published_title", length = 150)
    private String publishedTitle;
    @Column(name = "published_body", columnDefinition = "TEXT")
    private String publishedBody;
    @Column(nullable = false)
    private boolean published;
    @Column(name = "published_at")
    private LocalDateTime publishedAt;
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    @Version
    private Long version;

    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }
    public String getPublishedTitle() { return publishedTitle; }
    public void setPublishedTitle(String title) { this.publishedTitle = title; }
    public String getPublishedBody() { return publishedBody; }
    public void setPublishedBody(String body) { this.publishedBody = body; }
    public boolean isPublished() { return published; }
    public void setPublished(boolean published) { this.published = published; }
    public LocalDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(LocalDateTime date) { this.publishedAt = date; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Long getVersion() { return version; }
}
