package com.rental.modules.admin;

import com.rental.modules.admin.dto.request.AdminCreateUserRequest;
import com.rental.modules.admin.service.AdminCreateUserService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.service.*;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.server.ResponseStatusException;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

class AdminCreateUserServiceTest {
    final UserRepository users = mock(UserRepository.class);
    final BCryptPasswordEncoder passwords = new BCryptPasswordEncoder();
    final OtpService otp = mock(OtpService.class);
    final EmailService email = mock(EmailService.class);
    final AdminCreateUserService service = new AdminCreateUserService(users, passwords, otp, email);

    AdminCreateUserRequest request(Role role) {
        return new AdminCreateUserRequest("  Người dùng mới  ", "New@Example.com", "0901234567", "Password123!", role);
    }

    @Test void createsUnverifiedOwnerWithHashedPasswordAndEmailsOnlyTheOtp() {
        when(users.saveAndFlush(any())).thenAnswer(call -> {
            User user = call.getArgument(0); user.setUserId(7L); return user;
        });
        when(otp.generateAndStoreOtp("new@example.com")).thenReturn("123456");
        var result = service.create(request(Role.MEMBER));
        assertEquals("Người dùng mới", result.fullName()); assertEquals("new@example.com", result.email());
        assertEquals(Role.MEMBER, result.role()); assertEquals(UserStatus.ACTIVE, result.status()); assertFalse(result.verified());
        var captured = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(users).saveAndFlush(captured.capture());
        assertTrue(passwords.matches("Password123!", captured.getValue().getPasswordHash()));
        assertNotEquals("Password123!", captured.getValue().getPasswordHash());
        verify(email).sendOtpEmail("new@example.com", "123456");
    }

    @Test void duplicateEmailDoesNotOverwriteAnExistingAccountOrSendMail() {
        when(users.existsByEmailIgnoreCase("new@example.com")).thenReturn(true);
        assertEquals(409, assertThrows(ResponseStatusException.class, () -> service.create(request(Role.MEMBER))).getStatusCode().value());
        verify(users, never()).saveAndFlush(any()); verifyNoInteractions(email, otp);
    }

    @Test void duplicatePhoneAndDatabaseConflictsAreReportedWithoutSendingMail() {
        when(users.findByPhoneNumber("0901234567")).thenReturn(Optional.of(new User()));
        assertEquals(409, assertThrows(ResponseStatusException.class, () -> service.create(request(Role.MEMBER))).getStatusCode().value());
        when(users.findByPhoneNumber("0901234567")).thenReturn(Optional.empty());
        when(users.saveAndFlush(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("duplicate"));
        assertEquals(409, assertThrows(ResponseStatusException.class, () -> service.create(request(Role.MEMBER))).getStatusCode().value());
        verifyNoInteractions(email, otp);
    }

    @Test void adminRoleAndOverlongUnicodePasswordAreRejected() {
        assertEquals(400, assertThrows(ResponseStatusException.class, () -> service.create(request(Role.ADMIN))).getStatusCode().value());
        var request = new AdminCreateUserRequest("Name", "new@example.com", null, "é".repeat(40), Role.MEMBER);
        assertEquals(400, assertThrows(ResponseStatusException.class, () -> service.create(request)).getStatusCode().value());
        verifyNoInteractions(users, email, otp);
    }

    @Test void mailFailureClearsTheOtpAndDoesNotReturnSuccessfulCreation() {
        when(otp.generateAndStoreOtp("new@example.com")).thenReturn("123456");
        doThrow(new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Email unavailable"))
            .when(email).sendOtpEmail(anyString(), anyString());
        assertEquals(503, assertThrows(ResponseStatusException.class, () -> service.create(request(Role.MEMBER))).getStatusCode().value());
        verify(otp).discardOtp("new@example.com");
    }
}
