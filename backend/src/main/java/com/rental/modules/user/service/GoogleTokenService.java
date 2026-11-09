package com.rental.modules.user.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.List;

@Service
public class GoogleTokenService {
    private final GoogleIdTokenVerifier verifier;

    public GoogleTokenService(@Value("${app.google.client-id:}") String clientId) {
        if (clientId.isBlank() || clientId.contains("example")) {
            verifier = null;
        } else {
            verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), GsonFactory.getDefaultInstance())
                    .setAudience(List.of(clientId.trim())).build();
        }
    }

    public GoogleIdToken.Payload verify(String token) {
        if (verifier == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Đăng nhập Google chưa được cấu hình trên máy chủ.");
        }
        if (token == null || token.isBlank() || token.length() > 8192) {
            throw invalidToken();
        }
        GoogleIdToken result;
        try {
            result = GoogleIdToken.parse(GsonFactory.getDefaultInstance(), token);
        } catch (IOException | IllegalArgumentException exception) {
            throw invalidToken();
        }
        try {
            if (!verifier.verify(result)) throw invalidToken();
            return result.getPayload();
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Chưa kết nối được Google. Vui lòng thử lại.");
        } catch (GeneralSecurityException | IllegalArgumentException exception) {
            throw invalidToken();
        }
    }

    private ResponseStatusException invalidToken() {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                "Thông tin đăng nhập Google không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.");
    }
}
