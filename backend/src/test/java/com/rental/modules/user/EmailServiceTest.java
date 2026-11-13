package com.rental.modules.user;

import com.rental.modules.user.service.EmailService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

@ExtendWith(OutputCaptureExtension.class)
class EmailServiceTest {
    private static final String API_URL = "https://api.brevo.com/v3/smtp/email";

    @Test
    void sendsTransactionalEmailThroughBrevoHttpsApi() {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        EmailService service = new EmailService(builder, "test-api-key", "sender@example.com", "Rental Management");

        server.expect(requestTo(API_URL))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("api-key", "test-api-key"))
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(content().string(org.hamcrest.Matchers.allOf(
                        org.hamcrest.Matchers.containsString("sender@example.com"),
                        org.hamcrest.Matchers.containsString("tenant@example.com"),
                        org.hamcrest.Matchers.containsString("123456"))))
                .andRespond(withSuccess("{\"messageId\":\"test-message\"}", MediaType.APPLICATION_JSON));

        service.sendOtpEmail("tenant@example.com", "123456");
        server.verify();
    }

    @Test
    void providerFailureReturnsUnavailableWithoutLeakingOtp() {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        EmailService service = new EmailService(builder, "test-api-key", "sender@example.com", "Rental Management");
        server.expect(requestTo(API_URL))
                .andRespond(withStatus(HttpStatus.UNAUTHORIZED)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body("{\"message\":\"invalid api key\"}"));

        var error = assertThrows(ResponseStatusException.class,
                () -> service.sendOtpEmail("tenant@example.com", "123456"));

        assertEquals(503, error.getStatusCode().value());
        assertFalse(error.getReason().contains("123456"));
        server.verify();
    }

    @Test
    void logsProviderFailureWithoutEmailOrOtp(CapturedOutput output) {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        EmailService service = new EmailService(builder, "test-api-key", "sender@example.com", "Rental Management");
        server.expect(requestTo(API_URL))
                .andRespond(withStatus(HttpStatus.BAD_GATEWAY)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body("{\"message\":\"private provider detail\"}"));

        assertThrows(ResponseStatusException.class,
                () -> service.sendOtpEmail("tenant@example.com", "123456"));

        assertTrue(output.getAll().contains("HTTP 502"));
        assertFalse(output.getAll().contains("tenant@example.com"));
        assertFalse(output.getAll().contains("123456"));
        assertFalse(output.getAll().contains("private provider detail"));
        server.verify();
    }

    @Test
    void missingProviderConfigurationReturnsUnavailable() {
        EmailService service = new EmailService(RestClient.builder(), "", "", "Rental Management");

        var error = assertThrows(ResponseStatusException.class,
                () -> service.sendOtpEmail("tenant@example.com", "123456"));

        assertEquals(503, error.getStatusCode().value());
    }
}
