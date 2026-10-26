package com.rental.modules.report;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class ReportServiceTest {
    @Test void invalidRangesAreRejectedBeforeQuerying() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        ReportService service = new ReportService(jdbc);
        LocalDate day = LocalDate.of(2026, 1, 1);
        assertEquals(400, assertThrows(ResponseStatusException.class, () -> service.report(null, day)).getStatusCode().value());
        assertThrows(ResponseStatusException.class, () -> service.report(day, null));
        assertThrows(ResponseStatusException.class, () -> service.report(day, day.minusDays(1)));
        assertThrows(ResponseStatusException.class, () -> service.report(day, day.plusDays(366)));
        assertThrows(ResponseStatusException.class, () -> service.report(LocalDate.MAX, LocalDate.MAX));
        verifyNoInteractions(jdbc);
    }
}
