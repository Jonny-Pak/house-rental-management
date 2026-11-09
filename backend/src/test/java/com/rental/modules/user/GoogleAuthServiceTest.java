package com.rental.modules.user;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload;
import com.rental.core.security.JwtService;
import com.rental.modules.subscription.service.DefaultMembershipService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.service.GoogleAuthService;
import com.rental.modules.user.service.GoogleTokenService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class GoogleAuthServiceTest {
    GoogleTokenService tokens = mock(GoogleTokenService.class);
    UserRepository users = mock(UserRepository.class);
    DefaultMembershipService membership = mock(DefaultMembershipService.class);
    JwtService jwt = mock(JwtService.class);
    GoogleAuthService service = new GoogleAuthService(tokens, users, membership, jwt);
    Payload profile;

    @BeforeEach void setup() {
        profile = new Payload().setSubject("google-123").setEmail("member@gmail.com").setEmailVerified(true);
        profile.set("name", "Google Member");
        profile.set("picture", "https://example.com/avatar.jpg");
        when(tokens.verify("valid-token")).thenReturn(profile);
        when(users.saveAndFlush(any())).thenAnswer(call -> {
            User user = call.getArgument(0);
            if (user.getUserId() == null) user.setUserId(10L);
            return user;
        });
        when(jwt.generateAccessToken(any())).thenReturn("access");
        when(jwt.generateRefreshToken(any())).thenReturn("refresh");
    }

    User existing() {
        User user = new User();
        user.setUserId(20L); user.setFullName("Original name"); user.setEmail("member@gmail.com");
        user.setRole(Role.MEMBER); user.setStatus(UserStatus.ACTIVE); user.setIsVerified(true);
        user.setPasswordHash("password-hash"); user.setPhoneNumber("0900000000");
        return user;
    }

    @Test void createsVerifiedMemberAndGrantsBasicMembership() {
        var response = service.login("valid-token");
        assertEquals("MEMBER", response.getRole()); assertEquals("access", response.getAccessToken());
        var user = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(users).saveAndFlush(user.capture());
        assertEquals("google-123", user.getValue().getGoogleId());
        assertTrue(user.getValue().getIsVerified()); assertNull(user.getValue().getPasswordHash());
        assertEquals("Google Member", user.getValue().getFullName());
        verify(membership).assignIfMissing(10L);
    }

    @Test void linksVerifiedGmailAndPreservesProfilePasswordAndRole() {
        User user = existing(); user.setRole(Role.ADMIN);
        when(users.findGoogleEmailMatches("member@gmail.com")).thenReturn(List.of(user));
        service.login("valid-token");
        assertEquals(Role.ADMIN, user.getRole()); assertEquals("password-hash", user.getPasswordHash());
        assertEquals("Original name", user.getFullName()); assertEquals("0900000000", user.getPhoneNumber());
        assertEquals("google-123", user.getGoogleId());
        verify(membership).assignIfMissing(20L);
    }

    @Test void returningGoogleAccountUsesSubjectAndDoesNotCreateDuplicate() {
        User user = existing(); user.setGoogleId("google-123");
        when(users.findByGoogleId("google-123")).thenReturn(Optional.of(user));
        when(users.findForAdminUpdate(20L)).thenReturn(Optional.of(user));
        profile.setEmail("new-address@gmail.com");
        assertEquals(20L, service.login("valid-token").getUserId());
        verify(users, never()).saveAndFlush(any()); verify(users, never()).findGoogleEmailMatches(any());
    }

    @Test void unverifiedPasswordRegistrationCannotLeaveAttackersPasswordOrPhoneLinked() {
        User user = existing(); user.setIsVerified(false);
        when(users.findGoogleEmailMatches("member@gmail.com")).thenReturn(List.of(user));
        service.login("valid-token");
        assertNull(user.getPasswordHash()); assertNull(user.getPhoneNumber());
        assertEquals("Google Member", user.getFullName()); assertTrue(user.getIsVerified());
        assertEquals(1, user.getPasswordVersion());
    }

    @Test void lockedAccountsCannotLinkOrReceiveTokens() {
        User user = existing(); user.setStatus(UserStatus.LOCKED);
        when(users.findGoogleEmailMatches("member@gmail.com")).thenReturn(List.of(user));
        assertEquals(403, assertThrows(ResponseStatusException.class, () -> service.login("valid-token")).getStatusCode().value());
        assertNull(user.getGoogleId()); verifyNoInteractions(jwt, membership);
    }

    @Test void conflictingGoogleIdentityAndThirdPartyEmailCannotTakeOverAccount() {
        User user = existing(); user.setGoogleId("different-google-id");
        when(users.findGoogleEmailMatches("member@gmail.com")).thenReturn(List.of(user));
        assertThrows(ResponseStatusException.class, () -> service.login("valid-token"));
        user.setGoogleId(null); profile.setEmail("member@example.com");
        when(users.findGoogleEmailMatches("member@example.com")).thenReturn(List.of(user));
        assertThrows(ResponseStatusException.class, () -> service.login("valid-token"));
        verifyNoInteractions(jwt, membership);
        profile.setHostedDomain("example.com");
        service.login("valid-token");
        assertEquals("google-123", user.getGoogleId());
    }

    @Test void invalidOrUnverifiedGoogleProfileDoesNotTouchDatabase() {
        profile.setEmailVerified(false);
        assertThrows(ResponseStatusException.class, () -> service.login("valid-token"));
        profile.setEmailVerified(true).setSubject("");
        assertThrows(ResponseStatusException.class, () -> service.login("valid-token"));
        verifyNoInteractions(users, membership, jwt);
    }

    @Test void caseDuplicateEmailsAreRejectedRatherThanChoosingAnotherUser() {
        when(users.findGoogleEmailMatches("member@gmail.com")).thenReturn(List.of(existing(), existing()));
        assertEquals(409, assertThrows(ResponseStatusException.class, () -> service.login("valid-token")).getStatusCode().value());
        verifyNoInteractions(jwt, membership);
    }

    @Test void invalidTokenStopsBeforeAnyAccountChange() {
        when(tokens.verify("forged")).thenThrow(new ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED));
        assertThrows(ResponseStatusException.class, () -> service.login("forged"));
        verifyNoInteractions(users, jwt, membership);
    }
}
