package com.rental.modules.user;
import com.rental.modules.user.service.OtpService;
import java.time.Clock;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class OtpServiceTest {
    @Test void codeIsSixDigitsAndSingleUse() {
        Clock clock=mock(Clock.class); when(clock.millis()).thenReturn(0L);
        OtpService service=new OtpService(clock);
        String code=service.generateAndStoreOtp("tenant@example.com");
        assertTrue(code.matches("[0-9]{6}"));
        assertFalse(service.validateOtp("other@example.com",code));
        assertTrue(service.validateOtp("tenant@example.com",code));
        assertFalse(service.validateOtp("tenant@example.com",code));
    }
    @Test void codeExpiresAfterFiveMinutes() {
        Clock clock=mock(Clock.class); when(clock.millis()).thenReturn(0L);
        OtpService service=new OtpService(clock);
        String code=service.generateAndStoreOtp("tenant@example.com");
        when(clock.millis()).thenReturn(300000L);
        assertFalse(service.validateOtp("tenant@example.com",code));
    }
    @Test void resendCooldownAndFailedDeliveryCleanupWork() {
        Clock clock=mock(Clock.class); when(clock.millis()).thenReturn(0L);
        OtpService service=new OtpService(clock);
        service.generateAndStoreOtp("tenant@example.com");
        var error=assertThrows(ResponseStatusException.class,()->service.generateAndStoreOtp("tenant@example.com"));
        assertEquals(429,error.getStatusCode().value());
        service.discardOtp("tenant@example.com");
        assertDoesNotThrow(()->service.generateAndStoreOtp("tenant@example.com"));
        when(clock.millis()).thenReturn(60000L);
        assertDoesNotThrow(()->service.generateAndStoreOtp("tenant@example.com"));
    }
}
