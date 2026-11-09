package com.rental.modules.notification;

import com.rental.modules.notification.service.NotificationService;
import com.rental.modules.notification.repository.NotificationRepository;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.domain.enums.UserStatus;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
import static org.junit.jupiter.api.Assertions.*;

class NotificationServiceTest {
    @Test void readingIsAccountScopedAndIdempotent() {
        var repository = mock(NotificationRepository.class);
        var service = new NotificationService(repository, mock(UserRepository.class));
        when(repository.existsByIdAndUserId(7L, 1L)).thenReturn(true);
        service.markRead(1L, 7L); service.markRead(1L, 7L);
        verify(repository, times(2)).markRead(7L, 1L);
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> service.markRead(99L, 7L));
        verify(repository, never()).markRead(7L, 99L);
        service.markAllRead(1L); verify(repository).markAllRead(1L);
    }

    @Test void unreadAndDeleteCannotModifyAnotherAccount() {
        var repository = mock(NotificationRepository.class);
        var service = new NotificationService(repository, mock(UserRepository.class));
        when(repository.existsByIdAndUserId(7L, 1L)).thenReturn(true);
        service.markUnread(1L, 7L);
        service.delete(1L, 7L);
        verify(repository).markUnread(7L, 1L);
        verify(repository).deleteOwned(7L, 1L);
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> service.markUnread(99L, 7L));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> service.delete(99L, 7L));
        verify(repository, never()).deleteOwned(7L, 99L);
        verify(repository, never()).markUnread(7L, 99L);
        service.deleteRead(1L);
        verify(repository).deleteRead(1L);
    }

    @Test void broadcastOnlyIncludesActiveVerifiedAccounts() {
        var repository = mock(NotificationRepository.class);
        var users = mock(UserRepository.class);
        when(users.findVerifiedIds(UserStatus.ACTIVE)).thenReturn(List.of(1L, 2L));
        var service = new NotificationService(repository, users);
        assertEquals(2, service.broadcast(" Thông báo ", " Nội dung "));
        verify(repository).save(argThat(n -> n.getUserId() == 1L && n.getType().equals("SYSTEM") && n.getTitle().equals("Thông báo") && !n.isRead()));
        verify(repository).save(argThat(n -> n.getUserId() == 2L && n.getContent().equals("Nội dung")));
    }

    @Test void invalidPagesDoNotQueryAndLongBusinessMessagesFitTheDatabase() {
        var repository = mock(NotificationRepository.class);
        var service = new NotificationService(repository, mock(UserRepository.class));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> service.inbox(1L, -1, false));
        verifyNoInteractions(repository);
        service.send(1L, "LISTING_REJECTED", "Tin bị từ chối", "A".repeat(1000), 5L, null);
        verify(repository).save(argThat(n -> n.getContent().length() == 500 && n.getListingId() == 5L));
    }
}
