package com.rental.modules.user;

import com.rental.core.security.JwtService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.qr.*;
import com.rental.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import java.time.Instant;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class QrLoginServiceTest {
    final QrLoginRepository sessions = mock(QrLoginRepository.class);
    final UserRepository users = mock(UserRepository.class);
    final JwtService jwt = mock(JwtService.class);
    final Map<String, QrLoginSession> stored = new HashMap<>();
    final QrLoginService service = new QrLoginService(sessions, users, jwt, "http://localhost:8081");
    final User admin = new User();

    @BeforeEach void setup() {
        admin.setUserId(1L); admin.setEmail("admin@example.com"); admin.setRole(Role.ADMIN);
        admin.setStatus(UserStatus.ACTIVE); admin.setIsVerified(true);
        when(users.findForAdminUpdate(1L)).thenReturn(Optional.of(admin));
        when(sessions.save(any())).thenAnswer(call -> {
            QrLoginSession session = call.getArgument(0); stored.put(session.getId(), session); return session;
        });
        when(sessions.findForUpdate(anyString())).thenAnswer(call -> Optional.ofNullable(stored.get(call.getArgument(0))));
        when(jwt.generateAccessToken(admin)).thenReturn("test-access");
        when(jwt.generateRefreshToken(admin)).thenReturn("test-refresh");
    }

    private QrLoginService.Started start() { return service.start("http://localhost:8081", "Chrome/1 Windows", "127.0.0.1"); }
    private String token(QrLoginService.Started session) { return session.qrData().split("token=")[1]; }
    private void approve(QrLoginService.Started session) {
        service.preview(session.id(), token(session), 1L);
        service.decide(session.id(), token(session), 1L, true);
    }

    @Test void secretsAreDifferentHashedAndNeverPutInTheWrongChannel() {
        var session = start();
        assertNotEquals(session.browserSecret(), token(session));
        assertFalse(session.qrData().contains(session.browserSecret()));
        assertNotEquals(session.browserSecret(), stored.get(session.id()).getBrowserSecretHash());
        assertNotEquals(token(session), stored.get(session.id()).getScanSecretHash());
        assertEquals(6, session.verificationCode().length());
        assertTrue(session.expiresAt().isAfter(Instant.now().plusSeconds(118)));
        assertEquals("PENDING", service.status(session.id(), session.browserSecret()).status());
        assertEquals(403, assertThrows(ResponseStatusException.class,
            () -> service.status(session.id(), token(session))).getStatusCode().value());
        verifyNoInteractions(jwt);
    }

    @Test void adminMustScanThenConfirmBeforeBrowserCanConsumeOnlyOnce() {
        var session = start();
        assertThrows(ResponseStatusException.class, () -> service.consume(session.id(), session.browserSecret()));
        var preview = service.preview(session.id(), token(session), 1L);
        assertEquals("Chrome trên Windows", preview.browserName());
        assertEquals("http://localhost:8081", preview.website());
        assertEquals(session.verificationCode(), preview.verificationCode());
        assertEquals("SCANNED", service.status(session.id(), session.browserSecret()).status());
        verifyNoInteractions(jwt);
        service.decide(session.id(), token(session), 1L, true);
        assertEquals("APPROVED", service.status(session.id(), session.browserSecret()).status());
        var auth = service.consume(session.id(), session.browserSecret());
        assertEquals("ADMIN", auth.getRole()); assertEquals(1L, auth.getUserId());
        assertEquals("test-access", auth.getAccessToken());
        assertEquals("CONSUMED", service.status(session.id(), session.browserSecret()).status());
        assertThrows(ResponseStatusException.class, () -> service.consume(session.id(), session.browserSecret()));
        verify(jwt, times(1)).generateAccessToken(admin);
    }

    @Test void memberLockedAndUnverifiedAccountsCannotApprove() {
        for (String invalid : List.of("member", "locked", "unverified")) {
            var session = start();
            admin.setRole(invalid.equals("member") ? Role.MEMBER : Role.ADMIN);
            admin.setStatus(invalid.equals("locked") ? UserStatus.LOCKED : UserStatus.ACTIVE);
            admin.setIsVerified(!invalid.equals("unverified"));
            assertEquals(403, assertThrows(ResponseStatusException.class,
                () -> service.preview(session.id(), token(session), 1L)).getStatusCode().value());
        }
        verifyNoInteractions(jwt);
    }

    @Test void roleLockOrPasswordChangesAfterApprovalBlockTokenIssuance() {
        for (String change : List.of("role", "lock", "password")) {
            admin.setRole(Role.ADMIN); admin.setStatus(UserStatus.ACTIVE); admin.setPasswordVersion(0);
            var session = start(); approve(session);
            if (change.equals("role")) admin.setRole(Role.MEMBER);
            if (change.equals("lock")) admin.setStatus(UserStatus.LOCKED);
            if (change.equals("password")) admin.setPasswordVersion(1);
            assertThrows(ResponseStatusException.class, () -> service.consume(session.id(), session.browserSecret()));
        }
        verifyNoInteractions(jwt);
    }

    @Test void expiredRejectedAndCancelledSessionsCannotBeReused() {
        var expired = start(); approve(expired);
        stored.get(expired.id()).setExpiresAt(Instant.now().minusSeconds(1));
        assertEquals("EXPIRED", service.status(expired.id(), expired.browserSecret()).status());
        assertThrows(ResponseStatusException.class, () -> service.consume(expired.id(), expired.browserSecret()));
        var rejected = start(); service.preview(rejected.id(), token(rejected), 1L);
        service.decide(rejected.id(), token(rejected), 1L, false);
        assertEquals("REJECTED", service.status(rejected.id(), rejected.browserSecret()).status());
        assertThrows(ResponseStatusException.class, () -> service.preview(rejected.id(), token(rejected), 1L));
        var cancelled = start(); approve(cancelled); service.cancel(cancelled.id(), cancelled.browserSecret());
        assertEquals("CANCELLED", service.status(cancelled.id(), cancelled.browserSecret()).status());
        assertThrows(ResponseStatusException.class, () -> service.consume(cancelled.id(), cancelled.browserSecret()));
        verifyNoInteractions(jwt);
    }

    @Test void anotherAdminCannotTakeOverTheScannedSession() {
        User other = new User(); other.setUserId(2L); other.setRole(Role.ADMIN); other.setStatus(UserStatus.ACTIVE); other.setIsVerified(true);
        when(users.findForAdminUpdate(2L)).thenReturn(Optional.of(other));
        var session = start(); service.preview(session.id(), token(session), 1L);
        assertThrows(ResponseStatusException.class, () -> service.preview(session.id(), token(session), 2L));
        assertThrows(ResponseStatusException.class, () -> service.decide(session.id(), token(session), 2L, true));
        assertThrows(ResponseStatusException.class, () -> service.preview(session.id(), session.browserSecret(), 1L));
        var unscanned = start();
        assertThrows(ResponseStatusException.class, () -> service.decide(unscanned.id(), token(unscanned), 1L, true));
    }

    @Test void unknownOriginInvalidIdsAndRapidCreationAreRejected() {
        assertEquals(403, assertThrows(ResponseStatusException.class,
            () -> service.start("https://other.example", "Chrome", "127.0.0.1")).getStatusCode().value());
        assertThrows(ResponseStatusException.class, () -> service.status("bad-id", "x"));
        when(sessions.countByRequesterHashAndCreatedAtAfter(anyString(), any())).thenReturn(20L);
        assertEquals(429, assertThrows(ResponseStatusException.class, this::start).getStatusCode().value());
        verify(sessions, never()).save(any());
    }

    @Test void expiryIsCheckedAgainAfterWaitingForTheAccountLock() {
        var session = start(); approve(session);
        when(users.findForAdminUpdate(1L)).thenAnswer(call -> {
            stored.get(session.id()).setExpiresAt(Instant.now().minusSeconds(1));
            return Optional.of(admin);
        });
        assertThrows(ResponseStatusException.class, () -> service.consume(session.id(), session.browserSecret()));
        verifyNoInteractions(jwt);
    }
}
