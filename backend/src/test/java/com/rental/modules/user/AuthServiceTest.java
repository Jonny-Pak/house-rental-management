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
    AuthService service = new AuthService(users, encoder, otp, mail, authentication, jwt);

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

}
