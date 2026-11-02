package com.rental.modules.user.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload;
import com.rental.core.security.JwtService;
import com.rental.modules.subscription.service.DefaultMembershipService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.dto.response.AuthResponse;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@Service
public class GoogleAuthService {
    private final GoogleTokenService googleTokens;
    private final UserRepository users;
    private final DefaultMembershipService membership;
    private final JwtService jwt;

    public GoogleAuthService(GoogleTokenService googleTokens, UserRepository users,
                             DefaultMembershipService membership, JwtService jwt) {
        this.googleTokens = googleTokens;
        this.users = users;
        this.membership = membership;
        this.jwt = jwt;
    }

    @Transactional
    public AuthResponse login(String idToken) {
        Payload profile = googleTokens.verify(idToken);
        validateProfile(profile);
        User user = findOrCreateUser(profile);
        membership.assignIfMissing(user.getUserId());
        AuthResponse response = new AuthResponse();
        response.setUserId(user.getUserId());
        response.setRole(user.getRole().name());
        response.setAccessToken(jwt.generateAccessToken(user));
        response.setRefreshToken(jwt.generateRefreshToken(user));
        return response;
    }

    private void validateProfile(Payload profile) {
        String email = profile.getEmail();
        String subject = profile.getSubject();
        if (!Boolean.TRUE.equals(profile.getEmailVerified()) || email == null || email.isBlank()
                || email.length() > 150 || !email.contains("@")
                || subject == null || subject.isBlank() || subject.length() > 100) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Tài khoản Google chưa có email hợp lệ đã xác minh.");
        }
    }

    private User findOrCreateUser(Payload profile) {
        var linked = users.findByGoogleId(profile.getSubject());
        if (linked.isPresent()) {
            User user = users.findForAdminUpdate(linked.get().getUserId()).orElseThrow();
            requireActive(user);
            return user;
        }
        String email = profile.getEmail().trim().toLowerCase(Locale.ROOT);
        var matches = users.findGoogleEmailMatches(email);
        if (matches.size() > 1) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Email đang trùng nhiều tài khoản. Vui lòng liên hệ hỗ trợ.");
        }
        if (matches.isEmpty()) return createUser(profile, email);
        User user = matches.getFirst();
        requireActive(user);
        if (user.getGoogleId() != null && !profile.getSubject().equals(user.getGoogleId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Email đã được liên kết với tài khoản Google khác.");
        }
        if (!email.endsWith("@gmail.com") && profile.getHostedDomain() == null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Email này đã có tài khoản. Vui lòng đăng nhập bằng mật khẩu.");
        }
        if (!Boolean.TRUE.equals(user.getIsVerified())) {
            user.setPasswordHash(null);
            user.setPhoneNumber(null);
            user.setFullName(profileName(profile, email));
            user.setPasswordVersion(user.getPasswordVersion() + 1);
        }
        user.setGoogleId(profile.getSubject());
        user.setIsVerified(true);
        if (user.getAvatarUrl() == null) user.setAvatarUrl(avatar(profile));
        return users.saveAndFlush(user);
    }

    private User createUser(Payload profile, String email) {
        User user = new User();
        user.setEmail(email);
        user.setFullName(profileName(profile, email));
        user.setGoogleId(profile.getSubject());
        user.setAvatarUrl(avatar(profile));
        user.setRole(Role.MEMBER);
        user.setStatus(UserStatus.ACTIVE);
        user.setIsVerified(true);
        return users.saveAndFlush(user);
    }

    private void requireActive(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Tài khoản đã bị khóa. Vui lòng liên hệ hỗ trợ.");
        }
    }

    private String profileName(Payload profile, String email) {
        Object value = profile.get("name");
        String name = value instanceof String ? ((String) value).trim() : "";
        if (name.isEmpty()) return email.substring(0, email.indexOf('@'));
        return name.substring(0, Math.min(name.length(), 150));
    }

    private String avatar(Payload profile) {
        Object value = profile.get("picture");
        if (value instanceof String url && url.startsWith("https://") && url.length() <= 255) return url;
        return null;
    }
}
