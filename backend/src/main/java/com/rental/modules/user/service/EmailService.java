package com.rental.modules.user.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }


    @Async
    public void sendOtpEmail(String toEmail, String otp) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(toEmail);
            message.setSubject("[Rental Management] Mã OTP của bạn");
            message.setText("Mã OTP của bạn là: " + otp + "\n\nMã này sẽ hết hạn sau 5 phút.\nKhông chia sẻ mã này với bất kỳ ai.");
            mailSender.send(message);
            log.info("Mã OTP đã được gửi thành công đến {}: {}", toEmail, otp);
        } catch (org.springframework.mail.MailException e) {
            log.error("Không thể gửi mã OTP đến {}: {}", toEmail, e.getMessage());
        }
    }
}
