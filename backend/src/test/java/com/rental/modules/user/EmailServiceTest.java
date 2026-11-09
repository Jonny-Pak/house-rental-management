package com.rental.modules.user;
import com.rental.modules.user.service.EmailService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import java.net.SocketTimeoutException;
import java.util.Map;
import org.mockito.ArgumentCaptor;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.web.server.ResponseStatusException;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
@ExtendWith(OutputCaptureExtension.class)
class EmailServiceTest {
    @Test void messageHasExplicitSenderAndRecipient() {
        JavaMailSender sender = mock(JavaMailSender.class);
        EmailService service = new EmailService(sender, "sender@example.com");
        service.sendOtpEmail("tenant@example.com", "123456");
        var message = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(sender).send(message.capture());
        assertEquals("sender@example.com", message.getValue().getFrom());
        assertArrayEquals(new String[]{"tenant@example.com"}, message.getValue().getTo());
        assertTrue(message.getValue().getText().contains("123456"));
    }
    @Test void smtpFailureIsReportedInsteadOfIgnored() {
        JavaMailSender sender = mock(JavaMailSender.class);
        doThrow(new MailSendException("SMTP failure")).when(sender).send(any(SimpleMailMessage.class));
        var error = assertThrows(ResponseStatusException.class,
                () -> new EmailService(sender,"sender@example.com").sendOtpEmail("tenant@example.com","123456"));
        assertEquals(503,error.getStatusCode().value());
        assertFalse(error.getReason().contains("123456"));
    }
    @Test void logsNestedFailureWithoutEmailOrOtp(CapturedOutput output) {
        JavaMailSender sender = mock(JavaMailSender.class);
        SimpleMailMessage failedMessage = new SimpleMailMessage();
        failedMessage.setTo("tenant@example.com");
        failedMessage.setText("123456");
        var failure = new MailSendException("SMTP failure", null,
                Map.of(failedMessage, new SocketTimeoutException("private SMTP detail")));
        doThrow(failure).when(sender).send(any(SimpleMailMessage.class));
        assertThrows(ResponseStatusException.class,
                () -> new EmailService(sender, "sender@example.com").sendOtpEmail("tenant@example.com", "123456"));
        assertTrue(output.getAll().contains("SocketTimeoutException"));
        assertFalse(output.getAll().contains("tenant@example.com"));
        assertFalse(output.getAll().contains("123456"));
        assertFalse(output.getAll().contains("private SMTP detail"));
    }
    @Test void gmailSendingLimitHasClearMessage(CapturedOutput output) {
        JavaMailSender sender = mock(JavaMailSender.class);
        var smtpError = new jakarta.mail.MessagingException("550 5.4.5 Daily user sending limit exceeded");
        var failure = new MailSendException("Failed messages", null, Map.of(new SimpleMailMessage(), smtpError));
        doThrow(failure).when(sender).send(any(SimpleMailMessage.class));
        var error = assertThrows(ResponseStatusException.class,
                () -> new EmailService(sender, "sender@example.com").sendOtpEmail("tenant@example.com", "123456"));
        assertEquals(503, error.getStatusCode().value());
        assertTrue(error.getReason().contains("hết hạn mức gửi"));
        assertTrue(output.getAll().contains("SMTP 5.4.5"));
        assertFalse(output.getAll().contains("tenant@example.com"));
    }
}
