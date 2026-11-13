package com.rental.modules.user;

import com.rental.core.security.JwtService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.dto.request.LoginRequest;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.service.AuthService;
import com.rental.modules.user.service.EmailService;
import com.rental.modules.user.service.OtpService;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AuthServiceTest {
    UserRepository users = mock(UserRepository.class);
    AuthenticationManager authentication = mock(AuthenticationManager.class);
    JwtService jwt = mock(JwtService.class);
    PasswordEncoder encoder=mock(PasswordEncoder.class);
    OtpService otp=mock(OtpService.class);
    EmailService mail=mock(EmailService.class);
    com.rental.modules.subscription.service.DefaultMembershipService membership = mock(com.rental.modules.subscription.service.DefaultMembershipService.class);
    AuthService service = new AuthService(users, encoder, otp, mail, authentication, jwt, membership);

    @Test void verifiedUserStillReceivesTokensAndRole() {
        User user = new User();
        user.setUserId(7L); user.setRole(Role.MEMBER); user.setIsVerified(true);
        user.setStatus(com.rental.modules.user.domain.enums.UserStatus.ACTIVE);
        when(users.findByEmail("user@example.com")).thenReturn(Optional.of(user));
        when(jwt.generateAccessToken(user)).thenReturn("access");
        when(jwt.generateRefreshToken(user)).thenReturn("refresh");
        var response = service.login(new LoginRequest("user@example.com", "password"));
        assertEquals("access", response.getAccessToken());
        assertEquals("refresh", response.getRefreshToken());
        assertEquals("MEMBER", response.getRole());
        assertEquals(7L, response.getUserId());
        verify(authentication).authenticate(any());
        verify(membership).assignIfMissing(7L);
    }

    @Test void lockedUserCannotReceiveTokens() {
        User user = new User(); user.setIsVerified(true);
        user.setStatus(com.rental.modules.user.domain.enums.UserStatus.LOCKED);
        when(users.findByEmail("locked@example.com")).thenReturn(Optional.of(user));
        assertThrows(IllegalStateException.class, () -> service.login(new LoginRequest("locked@example.com", "password")));
        verifyNoInteractions(jwt);
    }

    @Test void missingUserCannotAuthenticate() {
        when(users.findByEmail("missing@example.com")).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> service.login(new LoginRequest("missing@example.com", "password")));
        verifyNoInteractions(authentication, jwt);
    }

    @Test void unverifiedUserCannotReceiveTokens() {
        User user = new User(); user.setIsVerified(false);
        when(users.findByEmail("user@example.com")).thenReturn(Optional.of(user));
        assertThrows(IllegalStateException.class, () -> service.login(new LoginRequest("user@example.com", "password")));
        verifyNoInteractions(authentication, jwt);
    }
    @Test void smtpFailurePreventsSuccessfulRegistrationResponseAndClearsCode() {
        var request = new com.rental.modules.user.dto.request.RegisterRequest(
                "Tenant", "tenant@example.com", "password", null, Role.MEMBER);
        when(users.findByEmail(request.getEmail())).thenReturn(Optional.empty());
        when(otp.generateAndStoreOtp(request.getEmail())).thenReturn("123456");
        doThrow(new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                .when(mail).sendOtpEmail(request.getEmail(),"123456");
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->service.register(request));
        verify(otp).discardOtp(request.getEmail());
    }
    @Test void unverifiedRegistrationCanRetryUsingOriginalPassword() {
        User user=new User(); user.setEmail("tenant@example.com"); user.setIsVerified(false);user.setPasswordHash("hash");
        when(users.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(encoder.matches("password","hash")).thenReturn(true);
        when(otp.generateAndStoreOtp(user.getEmail())).thenReturn("123456");
        var request=new com.rental.modules.user.dto.request.RegisterRequest("Tenant",user.getEmail(),"password",null,Role.MEMBER);
        service.register(request);
        verify(mail).sendOtpEmail(user.getEmail(),"123456");
        verify(users,never()).save(any());
    }
    @Test void verifiedUserCannotRequestAnotherVerificationCode() {
        User user=new User();user.setIsVerified(true);
        when(users.findByEmail("tenant@example.com")).thenReturn(Optional.of(user));
        assertThrows(IllegalArgumentException.class,()->service.resendOtp("tenant@example.com"));
        verifyNoInteractions(mail,otp);
    }

    @Test void validOtpActivatesUserAndAssignsDefaultMembership() {
        User user = new User(); user.setUserId(8L); user.setIsVerified(false);
        when(otp.validateOtp("new@example.com", "123456")).thenReturn(true);
        when(users.findByEmail("new@example.com")).thenReturn(Optional.of(user));
        service.verifyOtp(new com.rental.modules.user.dto.request.VerifyOtpRequest("new@example.com", "123456"));
        assertTrue(user.getIsVerified());
        verify(users).save(user);
        verify(membership).assignIfMissing(8L);
    }

    @Test void invalidOtpDoesNotActivateOrGrantMembership() {
        assertThrows(IllegalArgumentException.class, () -> service.verifyOtp(
            new com.rental.modules.user.dto.request.VerifyOtpRequest("new@example.com", "wrong")));
        verifyNoInteractions(users, membership);
    }

    @Test void duplicatePhoneNumberIsRejectedBeforeSavingOrSendingOtp() {
        var request = new com.rental.modules.user.dto.request.RegisterRequest(
                "Tenant", "tenant@example.com", "password123", "0912345678", Role.MEMBER);
        when(users.findByEmail("tenant@example.com")).thenReturn(Optional.empty());
        when(users.findByEmailIgnoreCase("tenant@example.com")).thenReturn(Optional.empty());
        when(users.findByPhoneNumber("0912345678")).thenReturn(Optional.of(new User()));

        var error = assertThrows(IllegalArgumentException.class, () -> service.register(request));
        assertEquals("Số điện thoại đã được sử dụng.", error.getMessage());
        verify(users, never()).save(any());
        verifyNoInteractions(otp, mail);
    }

    @Test void blankPhoneNormalizesToNullAndEmailNormalizesToLowercase() {
        var request = new com.rental.modules.user.dto.request.RegisterRequest(
                "  Nguyen Van A  ", "  NewUser@Example.COM ", "password123", "   ", Role.MEMBER);
        when(users.findByEmail("newuser@example.com")).thenReturn(Optional.empty());
        when(users.findByEmailIgnoreCase("newuser@example.com")).thenReturn(Optional.empty());
        when(encoder.encode("password123")).thenReturn("encoded-pw");
        when(otp.generateAndStoreOtp("newuser@example.com")).thenReturn("654321");

        service.register(request);

        var savedUser = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(users).save(savedUser.capture());
        assertEquals("Nguyen Van A", savedUser.getValue().getFullName());
        assertEquals("newuser@example.com", savedUser.getValue().getEmail());
        assertNull(savedUser.getValue().getPhoneNumber());
        verify(mail).sendOtpEmail("newuser@example.com", "654321");
    }

    @Test void endToEndRegisterOtpVerificationAndLoginFlow() {
        OtpService realOtp = new OtpService();
        AuthService flowService = new AuthService(users, encoder, realOtp, mail, authentication, jwt, membership);

        java.util.concurrent.atomic.AtomicReference<User> stored = new java.util.concurrent.atomic.AtomicReference<>();
        when(users.findByEmail("flow@example.com")).thenAnswer(inv -> Optional.ofNullable(stored.get()));
        when(users.findByEmailIgnoreCase("flow@example.com")).thenAnswer(inv -> Optional.ofNullable(stored.get()));
        when(users.findByPhoneNumber("0987654321")).thenReturn(Optional.empty());
        when(encoder.encode("secret123")).thenReturn("hashed-secret");
        when(users.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            if (u.getUserId() == null) u.setUserId(42L);
            stored.set(u);
            return u;
        });
        when(jwt.generateAccessToken(any())).thenReturn("jwt-access");
        when(jwt.generateRefreshToken(any())).thenReturn("jwt-refresh");

        var regRequest = new com.rental.modules.user.dto.request.RegisterRequest(
                "Flow User", "Flow@Example.com", "secret123", "0987654321", Role.MEMBER);
        String regMsg = flowService.register(regRequest);
        assertTrue(regMsg.contains("Đã gửi mã xác thực"));
        assertFalse(stored.get().getIsVerified());

        var sentOtp = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(mail).sendOtpEmail(eq("flow@example.com"), sentOtp.capture());
        String code = sentOtp.getValue();
        assertTrue(code.matches("[0-9]{6}"));

        // Unverified user cannot log in yet
        assertThrows(IllegalStateException.class,
                () -> flowService.login(new LoginRequest("FLOW@example.com", "secret123")));

        // Verify with mixed-case email and whitespace-padded OTP
        String verifyMsg = flowService.verifyOtp(
                new com.rental.modules.user.dto.request.VerifyOtpRequest(" FLOW@Example.com ", " " + code + " "));
        assertTrue(verifyMsg.contains("xác thực thành công"));
        assertTrue(stored.get().getIsVerified());
        verify(membership).assignIfMissing(42L);

        // OTP cannot be reused
        assertThrows(IllegalArgumentException.class,
                () -> flowService.verifyOtp(new com.rental.modules.user.dto.request.VerifyOtpRequest("flow@example.com", code)));

        // Verified user can log in
        var authResp = flowService.login(new LoginRequest("Flow@Example.com", "secret123"));
        assertEquals("jwt-access", authResp.getAccessToken());
        assertEquals(42L, authResp.getUserId());
    }

}
