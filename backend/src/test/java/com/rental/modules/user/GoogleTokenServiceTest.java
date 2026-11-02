package com.rental.modules.user;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.auth.oauth2.GooglePublicKeysManager;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.client.json.webtoken.JsonWebSignature;
import com.rental.modules.user.service.GoogleTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;
import java.security.KeyPairGenerator;
import java.security.KeyPair;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class GoogleTokenServiceTest {
    static final String CLIENT = "server.apps.googleusercontent.com";

    String sign(KeyPair key, String audience, String issuer, long expires) throws Exception {
        var payload = new GoogleIdToken.Payload().setSubject("subject-123").setEmail("member@gmail.com").setEmailVerified(true);
        payload.setAudience(audience); payload.setIssuer(issuer);
        payload.setIssuedAtTimeSeconds(System.currentTimeMillis() / 1000 - 30);
        payload.setExpirationTimeSeconds(expires);
        return JsonWebSignature.signUsingRsaSha256(key.getPrivate(), GsonFactory.getDefaultInstance(),
                new JsonWebSignature.Header().setAlgorithm("RS256").setType("JWT"), payload);
    }

    @Test void verifiesSignatureAudienceIssuerAndExpiryWithRealSignedTokens() throws Exception {
        var generator = KeyPairGenerator.getInstance("RSA"); generator.initialize(2048);
        KeyPair key = generator.generateKeyPair();
        var publicKeys = mock(GooglePublicKeysManager.class);
        when(publicKeys.getPublicKeys()).thenReturn(List.of(key.getPublic()));
        var verifier = new GoogleIdTokenVerifier.Builder(publicKeys).setAudience(List.of(CLIENT)).build();
        var service = new GoogleTokenService(CLIENT);
        ReflectionTestUtils.setField(service, "verifier", verifier);
        long future = System.currentTimeMillis() / 1000 + 3600;
        assertEquals("subject-123", service.verify(sign(key, CLIENT, "https://accounts.google.com", future)).getSubject());
        for (String token : List.of(
                sign(key, "another-client", "https://accounts.google.com", future),
                sign(key, CLIENT, "https://attacker.example.com", future),
                sign(key, CLIENT, "https://accounts.google.com", future - 7200),
                sign(generator.generateKeyPair(), CLIENT, "https://accounts.google.com", future), "not-a-jwt")) {
            assertEquals(401, assertThrows(ResponseStatusException.class, () -> service.verify(token)).getStatusCode().value());
        }
    }

    @Test void missingConfigurationDoesNotBreakStartupAndReturnsClearError() {
        var service = new GoogleTokenService("");
        assertEquals(503, assertThrows(ResponseStatusException.class, () -> service.verify("token")).getStatusCode().value());
    }
}
