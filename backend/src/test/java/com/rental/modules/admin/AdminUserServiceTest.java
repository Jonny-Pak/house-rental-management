package com.rental.modules.admin;

import com.rental.modules.admin.dto.request.AdminUpdateUserRequest;
import com.rental.modules.admin.service.AdminUserService;
import com.rental.modules.notification.service.NotificationService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import com.rental.modules.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AdminUserServiceTest {
    final UserRepository users = mock(UserRepository.class);
    final NotificationService notifications = mock(NotificationService.class);
    final AdminUserService service = new AdminUserService(users, notifications);

    User user(Role role) {
        User user = new User(); user.setUserId(7L); user.setRole(role);
        user.setEmail("tenant@example.com"); user.setFullName("Tenant");
        user.setStatus(UserStatus.ACTIVE); user.setIsVerified(true);
        user.setPasswordHash("private-hash");
        when(users.findForAdminUpdate(7L)).thenReturn(Optional.of(user));
        return user;
    }

    @Test void updatingProfileDoesNotChangeEmailVerificationOrPassword() {
        User user = user(Role.MEMBER);
        var result = service.update(7L, 1L, new AdminUpdateUserRequest("  Chủ nhà  ", "0901234567", Role.MEMBER));
        assertEquals("Chủ nhà", result.fullName()); assertEquals(Role.MEMBER, result.role());
        assertEquals("0901234567", result.phoneNumber());
        assertEquals("tenant@example.com", user.getEmail()); assertTrue(user.getIsVerified());
        assertEquals("private-hash", user.getPasswordHash());
        verify(users).saveAndFlush(user); verify(notifications).send(eq(7L), eq("SYSTEM"), anyString(), anyString(), isNull(), isNull());
    }

    @Test void adminAndOwnAccountCannotBeModifiedOrLocked() {
        user(Role.ADMIN);
        assertEquals(403, assertThrows(ResponseStatusException.class,
            () -> service.changeStatus(7L, 1L, UserStatus.LOCKED)).getStatusCode().value());
        assertThrows(ResponseStatusException.class, () -> service.update(7L, 1L, new AdminUpdateUserRequest("Name", "", Role.MEMBER)));
        user(Role.MEMBER);
        assertThrows(ResponseStatusException.class, () -> service.changeStatus(7L, 7L, UserStatus.LOCKED));
        verify(users, never()).saveAndFlush(any()); verifyNoInteractions(notifications);
    }

    @Test void cannotPromoteAnAccountToAdminOrUseAnotherPhoneNumber() {
        user(Role.MEMBER);
        assertEquals(400, assertThrows(ResponseStatusException.class,
            () -> service.update(7L, 1L, new AdminUpdateUserRequest("Name", "", Role.ADMIN))).getStatusCode().value());
        User other = new User(); other.setUserId(9L);
        when(users.findByPhoneNumber("0901234567")).thenReturn(Optional.of(other));
        assertEquals(409, assertThrows(ResponseStatusException.class,
            () -> service.update(7L, 1L, new AdminUpdateUserRequest("Name", "0901234567", Role.MEMBER))).getStatusCode().value());
        verify(users, never()).saveAndFlush(any());
    }

    @Test void lockAndUnlockAreIdempotentAndDoNotChangeEmailVerification() {
        User user = user(Role.MEMBER); user.setIsVerified(false);
        assertEquals(UserStatus.LOCKED, service.changeStatus(7L, 1L, UserStatus.LOCKED).status());
        service.changeStatus(7L, 1L, UserStatus.LOCKED);
        assertEquals(UserStatus.ACTIVE, service.changeStatus(7L, 1L, UserStatus.ACTIVE).status());
        assertFalse(user.getIsVerified());
        verify(users, times(2)).saveAndFlush(user);
        verify(notifications, times(2)).send(eq(7L), eq("SYSTEM"), anyString(), anyString(), isNull(), isNull());
    }

    @Test void invalidPagesAndMissingUserReturnClearErrors() {
        assertEquals(400, assertThrows(ResponseStatusException.class,
            () -> service.search("", null, null, null, -1)).getStatusCode().value());
        assertThrows(ResponseStatusException.class, () -> service.search("x".repeat(101), null, null, null, 0));
        assertEquals(404, assertThrows(ResponseStatusException.class, () -> service.detail(404L)).getStatusCode().value());
        assertThrows(ResponseStatusException.class, () -> service.changeStatus(404L, 1L, UserStatus.LOCKED));
    }
}
