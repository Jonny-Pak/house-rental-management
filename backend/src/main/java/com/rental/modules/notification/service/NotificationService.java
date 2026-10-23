package com.rental.modules.notification.service;

import com.rental.modules.notification.domain.Notification;
import com.rental.modules.notification.repository.NotificationRepository;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.domain.enums.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.util.List;

@Service
@Transactional
public class NotificationService {
    private final NotificationRepository notifications;
    private final UserRepository users;
    public NotificationService(NotificationRepository notifications, UserRepository users) {
        this.notifications = notifications; this.users = users;
    }

    public record Inbox(List<Notification> items, long unreadCount, boolean hasMore) {}

    @Transactional(readOnly = true)
    public Inbox inbox(Long userId, int page, boolean unreadOnly) {
        if (page < 0 || page > 10000) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trang không hợp lệ.");
        var pageable = PageRequest.of(page, 25);
        var rows = unreadOnly ? notifications.findByUserIdAndReadFalseOrderByCreatedAtDescIdDesc(userId, pageable)
            : notifications.findByUserIdOrderByCreatedAtDescIdDesc(userId, pageable);
        return new Inbox(rows.getContent(), unreadCount(userId), rows.hasNext());
    }

    @Transactional(readOnly = true)
    public long unreadCount(Long userId) { return notifications.countByUserIdAndReadFalse(userId); }

    public void markRead(Long userId, Long id) {
        requireOwned(userId, id);
        notifications.markRead(id, userId);
    }

    public void markUnread(Long userId, Long id) {
        requireOwned(userId, id);
        notifications.markUnread(id, userId);
    }

    public void delete(Long userId, Long id) {
        requireOwned(userId, id);
        notifications.deleteOwned(id, userId);
    }

    public void deleteRead(Long userId) { notifications.deleteRead(userId); }

    private void requireOwned(Long userId, Long id) {
        if (!notifications.existsByIdAndUserId(id, userId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy thông báo.");
        }
    }

    public void markAllRead(Long userId) { notifications.markAllRead(userId); }

    public void send(Long userId, String type, String title, String content, Long listingId, Long contractId) {
        String message = content == null ? "" : content;
        if (message.length() > 500) message = message.substring(0, 497) + "...";
        notifications.save(new Notification(userId, type, title, message, listingId, contractId));
    }

    public void notifyAdmins(String title, String content, Long listingId) {
        for (var admin : users.findByRoleAndStatus(Role.ADMIN, UserStatus.ACTIVE)) {
            send(admin.getUserId(), "LISTING_PENDING", title, content, listingId, null);
        }
    }

    public int broadcast(String title, String content) {
        var recipients = users.findVerifiedIds(UserStatus.ACTIVE);
        for (Long id : recipients) send(id, "SYSTEM", title.trim(), content.trim(), null, null);
        return recipients.size();
    }
}
