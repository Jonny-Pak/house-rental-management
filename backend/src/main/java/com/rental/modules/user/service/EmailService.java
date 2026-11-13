package com.rental.modules.user.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class EmailService {
    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
    private final RestClient brevoClient;
    private final String apiKey;
    private final String senderEmail;
    private final String senderName;

    public EmailService(
            RestClient.Builder restClientBuilder,
            @Value("${brevo.api-key:}") String apiKey,
            @Value("${brevo.sender-email:}") String senderEmail,
            @Value("${brevo.sender-name:Rental Management}") String senderName) {
        this.brevoClient = restClientBuilder.baseUrl("https://api.brevo.com/v3").build();
        this.apiKey = apiKey;
        this.senderEmail = senderEmail;
        this.senderName = senderName;
    }

    public void sendOtpEmail(String toEmail, String otp) {
        sendCode(toEmail, otp, "Mã xác thực tài khoản");
    }

    public void sendPasswordResetEmail(String toEmail, String otp) {
        sendCode(toEmail, otp, "Mã đặt lại mật khẩu");
    }

    private void sendCode(String toEmail, String otp, String subject) {
        if (apiKey == null || apiKey.isBlank() || senderEmail == null || senderEmail.isBlank()) {
            log.error("Gửi OTP thất bại qua Brevo: thiếu BREVO_API_KEY hoặc BREVO_SENDER_EMAIL");
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Dịch vụ gửi email chưa được cấu hình. Vui lòng thử lại sau.");
        }

        TransactionalEmail email = new TransactionalEmail(
                new Sender(senderName, senderEmail),
                List.of(new Recipient(toEmail)),
                "[Rental Management] " + subject,
                "Mã OTP của bạn là: " + otp + "\n\nMã có hiệu lực trong 5 phút. Không chia sẻ mã này.");
        try {
            brevoClient.post()
                    .uri("/smtp/email")
                    .header("api-key", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(email)
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientResponseException exception) {
            log.error("Gửi OTP thất bại qua Brevo: HTTP {}", exception.getStatusCode().value());
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Chưa gửi được email xác thực. Vui lòng thử lại sau.");
        } catch (RestClientException exception) {
            log.error("Gửi OTP thất bại qua Brevo: {}", exception.getClass().getSimpleName());
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Chưa gửi được email xác thực. Vui lòng thử lại sau.");
        }
    }

    private record Sender(String name, String email) {}

    private record Recipient(String email) {}

    private record TransactionalEmail(Sender sender, List<Recipient> to, String subject, String textContent) {}
}
