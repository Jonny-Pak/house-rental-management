package com.rental.modules.report;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public record ReportResponse(LocalDate from, LocalDate to, LocalDateTime generatedAt,
    long members, long listings, long contracts, BigDecimal revenue, long successfulPayments,
    List<Daily> daily, List<Breakdown> listingStatuses, List<Breakdown> contractStatuses) {
    public record Daily(LocalDate date, long members, long listings, long contracts, BigDecimal revenue) {}
    public record Breakdown(String status, long count) {}
}
