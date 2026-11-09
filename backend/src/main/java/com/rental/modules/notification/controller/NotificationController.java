package com.rental.modules.notification.controller;

import com.rental.core.security.CustomUserDetails;
import com.rental.modules.notification.service.NotificationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
public class NotificationController {
    private final NotificationService notifications;
    public NotificationController(NotificationService notifications) { this.notifications = notifications; }
    public record BroadcastRequest(@NotBlank @Size(max = 150) String title, @NotBlank @Size(max = 500) String content) {}

    @GetMapping("/api/v1/notifications")
    public NotificationService.Inbox inbox(@AuthenticationPrincipal CustomUserDetails user, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "false") boolean unreadOnly) {
        return notifications.inbox(user.getUser().getUserId(), page, unreadOnly);
    }
    @GetMapping("/api/v1/notifications/unread-count")
    public Map<String, Long> count(@AuthenticationPrincipal CustomUserDetails user) { return Map.of("count", notifications.unreadCount(user.getUser().getUserId())); }
    @PatchMapping("/api/v1/notifications/{id}/read")
    public void read(@AuthenticationPrincipal CustomUserDetails user, @PathVariable Long id) { notifications.markRead(user.getUser().getUserId(), id); }
    @PatchMapping("/api/v1/notifications/read-all")
    public void readAll(@AuthenticationPrincipal CustomUserDetails user) { notifications.markAllRead(user.getUser().getUserId()); }
    @PatchMapping("/api/v1/notifications/{id}/unread")
    public void unread(@AuthenticationPrincipal CustomUserDetails user, @PathVariable Long id) { notifications.markUnread(user.getUser().getUserId(), id); }
    @DeleteMapping("/api/v1/notifications/{id}")
    public void delete(@AuthenticationPrincipal CustomUserDetails user, @PathVariable Long id) { notifications.delete(user.getUser().getUserId(), id); }
    @DeleteMapping("/api/v1/notifications/read")
    public void deleteRead(@AuthenticationPrincipal CustomUserDetails user) { notifications.deleteRead(user.getUser().getUserId()); }
    @PostMapping("/api/v1/admin/notifications/broadcast")
    public Map<String, Integer> broadcast(@Valid @RequestBody BroadcastRequest request) { return Map.of("recipients", notifications.broadcast(request.title(), request.content())); }
}
