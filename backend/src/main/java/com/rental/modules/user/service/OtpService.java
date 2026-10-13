package com.rental.modules.user.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.security.SecureRandom;
import java.time.Clock;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {
    private final ConcurrentHashMap<String, OtpEntry> codes = new ConcurrentHashMap<>();
    private final SecureRandom random = new SecureRandom();
    private final Clock clock;

    public OtpService() {
        this(Clock.systemUTC());
    }

    public OtpService(Clock clock) {
        this.clock = clock;
    }

    public synchronized String generateAndStoreOtp(String email) {
        OtpEntry previous = codes.get(email);
        long now = clock.millis();
        if (previous != null && now - previous.createdAt < 60000) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Vui lòng chờ 60 giây trước khi gửi lại mã.");
        }
        String code = String.format("%06d", random.nextInt(1000000));
        codes.put(email, new OtpEntry(code, now));
        return code;
    }

    public boolean validateOtp(String email, String code) {
        OtpEntry entry = codes.get(email);
        if (entry == null) return false;
        if (clock.millis() - entry.createdAt >= 300000) {
            codes.remove(email, entry);
            return false;
        }
        if (!entry.code.equals(code)) return false;
        return codes.remove(email, entry);
    }

    public void discardOtp(String email) {
        codes.remove(email);
    }

    private static class OtpEntry {
        private final String code;
        private final long createdAt;
        private OtpEntry(String code, long createdAt) {
            this.code = code;
            this.createdAt = createdAt;
        }
    }
}
