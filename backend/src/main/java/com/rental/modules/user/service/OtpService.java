package com.rental.modules.user.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.security.SecureRandom;
import java.time.Clock;
import java.util.Locale;
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
        String key = normalizeKey(email);
        for (java.util.Map.Entry<String, OtpEntry> item : codes.entrySet()) {
            if (clock.millis() - item.getValue().createdAt >= 300000) codes.remove(item.getKey(), item.getValue());
        }
        OtpEntry previous = codes.get(key);
        long now = clock.millis();
        if (previous != null && now - previous.createdAt < 60000) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Vui lòng chờ 60 giây trước khi gửi lại mã.");
        }
        String code = String.format("%06d", random.nextInt(1000000));
        codes.put(key, new OtpEntry(code, now));
        return code;
    }

    public synchronized boolean validateOtp(String email, String code) {
        if (email == null || code == null) return false;
        String key = normalizeKey(email);
        String trimmedCode = code.trim();
        OtpEntry entry = codes.get(key);
        if (entry == null) return false;
        if (clock.millis() - entry.createdAt >= 300000) {
            codes.remove(key, entry);
            return false;
        }
        if (entry.attempts >= 5) return false;
        if (!entry.code.equals(trimmedCode)) {
            entry.attempts++;
            return false;
        }
        return codes.remove(key, entry);
    }

    public void discardOtp(String email) {
        if (email == null) return;
        codes.remove(normalizeKey(email));
    }

    private static String normalizeKey(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static class OtpEntry {
        private int attempts = 0;
        private final String code;
        private final long createdAt;
        private OtpEntry(String code, long createdAt) {
            this.code = code;
            this.createdAt = createdAt;
        }
    }
}
