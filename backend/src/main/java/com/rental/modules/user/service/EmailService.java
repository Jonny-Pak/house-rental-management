package com.rental.modules.user.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class EmailService {
    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
    private final JavaMailSender mailSender;
    private final String senderEmail;

    public EmailService(JavaMailSender mailSender, @Value("${spring.mail.username}") String senderEmail) {
        this.mailSender = mailSender;
        this.senderEmail = senderEmail;
    }

    public void sendOtpEmail(String toEmail, String otp) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(senderEmail);
        message.setTo(toEmail);
        message.setSubject("[Rental Management] Mã xác thực tài khoản");
        message.setText("Mã OTP của bạn là: " + otp + "\n\nMã có hiệu lực trong 5 phút. Không chia sẻ mã này.");
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            log.error("Gửi OTP thất bại: {}", getErrorTypes(exception));
            if (isSendingLimitExceeded(exception)) {
                log.error("Dịch vụ email đã vượt hạn mức gửi: SMTP 5.4.5");
                throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Dịch vụ email đã hết hạn mức gửi trong ngày. Vui lòng thử lại sau.");
            }
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Chưa gửi được email xác thực. Vui lòng thử lại sau.");
        }
    }

    private boolean isSendingLimitExceeded(MailException exception) {
        if (hasSendingLimitError(exception)) return true;
        if (exception instanceof MailSendException sendException) {
            for (Exception messageException : sendException.getMessageExceptions()) {
                if (hasSendingLimitError(messageException)) return true;
            }
        }
        return false;
    }

    private boolean hasSendingLimitError(Throwable error) {
        for (int depth = 0; error != null && depth < 8; depth++) {
            String message = error.getMessage();
            if (message != null && (message.contains("5.4.5")
                    || message.contains("Daily user sending limit exceeded"))) return true;
            error = error.getCause();
        }
        return false;
    }

    private String getErrorTypes(MailException exception) {
        String result = getCauseTypes(exception);
        if (exception instanceof MailSendException sendException) {
            for (Exception messageException : sendException.getMessageExceptions()) {
                result += "; " + getCauseTypes(messageException);
            }
        }
        return result;
    }

    private String getCauseTypes(Throwable error) {
        String result = error.getClass().getSimpleName();
        for (int depth = 0; depth < 8 && error.getCause() != null; depth++) {
            error = error.getCause();
            result += " -> " + error.getClass().getSimpleName();
        }
        return result;
    }
}
