package com.rental.modules.user.qr;

import com.rental.core.security.JwtService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.dto.response.AuthResponse;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class QrLoginService {
    private final QrLoginRepository sessions;
    private final UserRepository users;
    private final JwtService jwt;
    private final SecureRandom random = new SecureRandom();
    private final String adminOrigin;

    public QrLoginService(QrLoginRepository sessions, UserRepository users, JwtService jwt,
            @Value("${app.admin-web-origin:http://localhost:8081}") String adminOrigin) {
        this.sessions = sessions;
        this.users = users;
        this.jwt = jwt;
        this.adminOrigin = adminOrigin.replaceAll("/+$", "");
    }

    public record Started(String id, String browserSecret, String qrData, String verificationCode, Instant expiresAt) {}
    public record Status(String status) {}
    public record Preview(String website, String browserName, String verificationCode, Instant expiresAt) {}

    public Started start(String origin, String agent, String address) {
        if (origin == null || !origin.equalsIgnoreCase(adminOrigin)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Địa chỉ website Admin chưa khớp cấu hình ADMIN_WEB_ORIGIN.");
        }
        Instant now = Instant.now();
        sessions.deleteExpired(now.minusSeconds(3600));
        String requester = hash(address == null ? "unknown" : address);
        if (sessions.countByRequesterHashAndCreatedAtAfter(requester, now.minusSeconds(60)) >= 20) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Bạn tạo mã quá nhanh. Vui lòng chờ một phút.");
        }
        String browserSecret = secret();
        String scanSecret = secret();
        QrLoginSession session = new QrLoginSession();
        session.setId(UUID.randomUUID().toString());
        session.setBrowserSecretHash(hash(browserSecret));
        session.setScanSecretHash(hash(scanSecret));
        session.setVerificationCode(String.format("%06d", random.nextInt(1_000_000)));
        session.setBrowserName(browserName(agent));
        session.setWebsite(adminOrigin);
        session.setRequesterHash(requester);
        session.setCreatedAt(now);
        session.setExpiresAt(now.plusSeconds(120));
        sessions.save(session);
        String qrData = "houserental://admin-login/" + session.getId() + "?token=" + scanSecret;
        return new Started(session.getId(), browserSecret, qrData, session.getVerificationCode(), session.getExpiresAt());
    }

    public Status status(String id, String browserSecret) {
        QrLoginSession session = browserSession(id, browserSecret);
        return new Status(state(session));
    }

    public void cancel(String id, String browserSecret) {
        QrLoginSession session = browserSession(id, browserSecret);
        if (List.of("PENDING", "SCANNED", "APPROVED").contains(state(session))) {
            session.setStatus("CANCELLED");
        }
    }

    public Preview preview(String id, String scanToken, Long userId) {
        QrLoginSession session = scanSession(id, scanToken);
        User admin = requireAdmin(userId);
        requirePending(session);
        if (session.getAdmin() != null && !session.getAdmin().getUserId().equals(userId)) {
            throw conflict("Mã đã được mở trên một tài khoản Admin khác.");
        }
        session.setAdmin(admin);
        session.setPasswordVersion(admin.getPasswordVersion());
        session.setStatus("SCANNED");
        return new Preview(session.getWebsite(), session.getBrowserName(), session.getVerificationCode(), session.getExpiresAt());
    }

    public void decide(String id, String scanToken, Long userId, boolean approve) {
        QrLoginSession session = scanSession(id, scanToken);
        User admin = requireAdmin(userId);
        if (!"SCANNED".equals(state(session)) || session.getAdmin() == null
                || !session.getAdmin().getUserId().equals(userId)
                || session.getPasswordVersion() != admin.getPasswordVersion()) {
            throw conflict("Phiên không còn hợp lệ. Hãy tạo và quét mã mới.");
        }
        session.setStatus(approve ? "APPROVED" : "REJECTED");
    }

    public AuthResponse consume(String id, String browserSecret) {
        QrLoginSession session = browserSession(id, browserSecret);
        if (!"APPROVED".equals(state(session)) || session.getAdmin() == null) {
            throw conflict("Phiên chưa được xác nhận, đã hết hạn hoặc đã được sử dụng.");
        }
        User admin = requireAdmin(session.getAdmin().getUserId());
        if (!"APPROVED".equals(state(session))) {
            throw conflict("Mã QR đã hết hạn. Hãy tạo mã mới.");
        }
        if (session.getPasswordVersion() != admin.getPasswordVersion()) {
            throw conflict("Tài khoản đã đổi mật khẩu. Hãy tạo mã mới.");
        }
        String accessToken = jwt.generateAccessToken(admin);
        String refreshToken = jwt.generateRefreshToken(admin);
        session.setStatus("CONSUMED");
        return new AuthResponse(accessToken, refreshToken, admin.getUserId(), "ADMIN");
    }

    private QrLoginSession browserSession(String id, String secret) {
        QrLoginSession session = find(id);
        checkSecret(secret, session.getBrowserSecretHash());
        return session;
    }

    private QrLoginSession scanSession(String id, String token) {
        QrLoginSession session = find(id);
        checkSecret(token, session.getScanSecretHash());
        return session;
    }

    private QrLoginSession find(String id) {
        if (id == null || !id.matches("[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã phiên QR không hợp lệ.");
        }
        return sessions.findForUpdate(id).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phiên QR."));
    }

    private User requireAdmin(Long userId) {
        User user = users.findForAdminUpdate(userId).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.FORBIDDEN, "Không tìm thấy tài khoản Admin."));
        if (user.getRole() != Role.ADMIN || user.getStatus() != UserStatus.ACTIVE || !Boolean.TRUE.equals(user.getIsVerified())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ Admin đang hoạt động và đã xác thực mới được xác nhận QR.");
        }
        return user;
    }

    private void requirePending(QrLoginSession session) {
        if (!List.of("PENDING", "SCANNED").contains(state(session))) {
            throw conflict("Mã QR đã hết hạn, bị hủy hoặc đã được sử dụng.");
        }
    }

    private String state(QrLoginSession session) {
        if (List.of("PENDING", "SCANNED", "APPROVED").contains(session.getStatus())
                && !session.getExpiresAt().isAfter(Instant.now())) return "EXPIRED";
        return session.getStatus();
    }

    private void checkSecret(String secret, String expectedHash) {
        if (secret == null || !secret.matches("[A-Za-z0-9_-]{43}") || !MessageDigest.isEqual(
                hash(secret).getBytes(StandardCharsets.US_ASCII), expectedHash.getBytes(StandardCharsets.US_ASCII))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Khóa phiên QR không hợp lệ.");
        }
    }

    private String secret() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (java.security.NoSuchAlgorithmException error) {
            throw new IllegalStateException(error);
        }
    }

    private String browserName(String agent) {
        String text = agent == null ? "" : agent;
        String browser = "Trình duyệt";
        if (text.contains("Edg/")) browser = "Edge";
        else if (text.contains("Chrome/")) browser = "Chrome";
        else if (text.contains("Firefox/")) browser = "Firefox";
        else if (text.contains("Safari/")) browser = "Safari";
        if (text.contains("Windows")) return browser + " trên Windows";
        if (text.contains("Macintosh")) return browser + " trên macOS";
        return browser;
    }

    private ResponseStatusException conflict(String message) {
        return new ResponseStatusException(HttpStatus.CONFLICT, message);
    }
}
