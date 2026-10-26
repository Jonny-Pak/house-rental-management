package com.rental.modules.user;
import com.rental.core.security.*;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import static org.junit.jupiter.api.Assertions.*;
class PasswordTokenTest {
    @Test void changingPasswordInvalidatesAccessAndRefreshTokens() {
        JwtService jwt = new JwtService();
        String secret = java.util.Base64.getEncoder().encodeToString("test-only-32-byte-jwt-secret-key!!".getBytes(java.nio.charset.StandardCharsets.UTF_8));
        ReflectionTestUtils.setField(jwt, "secretKey", secret);
        ReflectionTestUtils.setField(jwt, "accessExpiration", 60000L);
        ReflectionTestUtils.setField(jwt, "refreshExpiration", 120000L);
        User user = new User(); user.setEmail("member@example.com"); user.setRole(Role.MEMBER);
        user.setStatus(UserStatus.ACTIVE); user.setIsVerified(true);
        CustomUserDetails details = new CustomUserDetails(user);
        String access = jwt.generateAccessToken(user), refresh = jwt.generateRefreshToken(user);
        assertTrue(jwt.isTokenValid(access, details)); assertTrue(jwt.isTokenValid(refresh, details));
        String legacy = io.jsonwebtoken.Jwts.builder().subject(user.getEmail()).expiration(new java.util.Date(System.currentTimeMillis()+60000))
            .signWith(io.jsonwebtoken.security.Keys.hmacShaKeyFor(java.util.Base64.getDecoder().decode(secret))).compact();
        assertTrue(jwt.isTokenValid(legacy, details));
        user.setPasswordVersion(1);
        assertFalse(jwt.isTokenValid(access, details)); assertFalse(jwt.isTokenValid(refresh, details)); assertFalse(jwt.isTokenValid(legacy, details));
        assertTrue(jwt.isTokenValid(jwt.generateAccessToken(user), details));
    }
}
