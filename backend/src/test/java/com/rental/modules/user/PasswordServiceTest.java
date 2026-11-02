package com.rental.modules.user;

import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import com.rental.modules.user.dto.request.*;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.server.ResponseStatusException;
import java.time.Clock;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PasswordServiceTest {
    UserRepository users = mock(UserRepository.class);
    EmailService email = mock(EmailService.class);
    Clock clock = mock(Clock.class);
    OtpService codes = new OtpService(clock);
    BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(4);
    PasswordService service = new PasswordService(users, encoder, codes, email);
    User user = new User();
    @BeforeEach void setup() {
        when(clock.millis()).thenReturn(0L);
        user.setEmail("member@example.com"); user.setStatus(UserStatus.ACTIVE); user.setIsVerified(true);
        user.setRole(Role.MEMBER); user.setPasswordHash(encoder.encode("OldPassword123"));
        when(users.findForPasswordUpdate(anyString())).thenReturn(Optional.of(user));
    }
    String sendCode() {
        service.requestReset(user.getEmail());
        ArgumentCaptor<String> code = ArgumentCaptor.forClass(String.class);
        verify(email).sendPasswordResetEmail(eq(user.getEmail()), code.capture());
        return code.getValue();
    }
    @Test void resetChangesHashRevokesOldVersionAndCodeCannotBeReused() {
        String code = sendCode();
        assertTrue(code.matches("[0-9]{6}"));
        service.reset(new ResetPasswordRequest(user.getEmail(), code, "NewPassword123"));
        assertTrue(encoder.matches("NewPassword123", user.getPasswordHash()));
        assertFalse(encoder.matches("OldPassword123", user.getPasswordHash()));
        assertEquals(1, user.getPasswordVersion());
        assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), code, "AnotherPassword123")));
        verify(users, times(1)).save(user);
    }
    @Test void incorrectExpiredAndRegistrationCodesCannotResetPassword() {
        String registration = codes.generateAndStoreOtp(user.getEmail());
        assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), registration, "NewPassword123")));
        String code = sendCode();
        String wrong = code.equals("000000") ? "000001" : "000000";
        assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), wrong, "NewPassword123")));
        when(clock.millis()).thenReturn(300000L);
        assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), code, "NewPassword123")));
        verify(users, never()).save(any());
    }
    @Test void fiveWrongAttemptsLockTheCodeAndResendHasCooldown() {
        String code = sendCode();
        assertEquals(429, assertThrows(ResponseStatusException.class, () -> service.requestReset(user.getEmail())).getStatusCode().value());
        String wrong = code.equals("000000") ? "000001" : "000000";
        for (int i = 0; i < 5; i++) assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), wrong, "NewPassword123")));
        assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), code, "NewPassword123")));
        when(clock.millis()).thenReturn(60000L);
        assertDoesNotThrow(() -> service.requestReset(user.getEmail()));
    }
    @Test void unknownLockedAndUnverifiedUsersDoNotReceiveMailOrRevealExistence() {
        when(users.findForPasswordUpdate("missing@example.com")).thenReturn(Optional.empty());
        String generic = service.requestReset("missing@example.com");
        user.setStatus(UserStatus.LOCKED);
        assertEquals(generic, service.requestReset(user.getEmail()));
        assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), "123456", "NewPassword123")));
        user.setStatus(UserStatus.ACTIVE); user.setIsVerified(false);
        assertEquals(generic, service.requestReset(user.getEmail()));
        verifyNoInteractions(email);
    }
    @Test void mailFailureIsVisibleAndCodeIsDiscardedForRetry() {
        doThrow(new ResponseStatusException(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE, "Mail unavailable"))
            .doNothing().when(email).sendPasswordResetEmail(anyString(), anyString());
        assertThrows(ResponseStatusException.class, () -> service.requestReset(user.getEmail()));
        assertDoesNotThrow(() -> service.requestReset(user.getEmail()));
    }
    @Test void changeRequiresCorrectCurrentAndDifferentValidNewPassword() {
        assertThrows(ResponseStatusException.class, () -> service.change(user.getEmail(), new ChangePasswordRequest("wrong", "NewPassword123")));
        assertThrows(ResponseStatusException.class, () -> service.change(user.getEmail(), new ChangePasswordRequest("OldPassword123", "OldPassword123")));
        assertThrows(ResponseStatusException.class, () -> service.change(user.getEmail(), new ChangePasswordRequest("OldPassword123", "ắ".repeat(25))));
        verify(users, never()).save(any());
        String resetCode = sendCode();
        service.change(user.getEmail(), new ChangePasswordRequest("OldPassword123", " NewPassword123 "));
        assertTrue(encoder.matches(" NewPassword123 ", user.getPasswordHash()));
        assertEquals(1, user.getPasswordVersion());
        assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), resetCode, "AnotherPassword123")));
    }
    @Test void resetCannotCheckExistingPasswordWithoutValidOtp() {
        String code = sendCode();
        String wrong = code.equals("000000") ? "000001" : "000000";
        var error = assertThrows(ResponseStatusException.class, () -> service.reset(new ResetPasswordRequest(user.getEmail(), wrong, "OldPassword123")));
        assertTrue(error.getReason().startsWith("Mã"));
        verify(users, never()).save(any());
    }
    @Test void googleOnlyAccountCanSetPasswordWithEmailOtp() {
        user.setPasswordHash(null);
        assertThrows(ResponseStatusException.class, () -> service.change(user.getEmail(), new ChangePasswordRequest("anything", "NewPassword123")));
        String code = sendCode();
        service.reset(new ResetPasswordRequest(user.getEmail(), code, "NewPassword123"));
        assertTrue(encoder.matches("NewPassword123", user.getPasswordHash()));
    }
}
