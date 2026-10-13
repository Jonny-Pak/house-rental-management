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
    AuthService service = new AuthService(users, mock(PasswordEncoder.class), mock(OtpService.class),
            mock(EmailService.class), authentication, jwt);

    @Test void verifiedUserStillReceivesTokensAndRole() {
        User user = new User();
        user.setUserId(7L); user.setRole(Role.USER); user.setIsVerified(true);
        when(users.findByEmail("user@example.com")).thenReturn(Optional.of(user));
        when(jwt.generateAccessToken(user)).thenReturn("access");
        when(jwt.generateRefreshToken(user)).thenReturn("refresh");
        var response = service.login(new LoginRequest("user@example.com", "password"));
        assertEquals("access", response.getAccessToken());
        assertEquals("refresh", response.getRefreshToken());
        assertEquals("USER", response.getRole());
        assertEquals(7L, response.getUserId());
        verify(authentication).authenticate(any());
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
}
