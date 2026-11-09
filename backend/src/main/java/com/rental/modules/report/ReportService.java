package com.rental.modules.report;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ReportService {
    private final JdbcTemplate jdbc;
    public ReportService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public ReportResponse report(LocalDate from, LocalDate to) {
        if (from == null || to == null || to.equals(LocalDate.MAX) || to.isBefore(from) || ChronoUnit.DAYS.between(from, to) > 365) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chọn khoảng thời gian hợp lệ, tối đa 366 ngày.");
        }
        LocalDateTime start = from.atStartOfDay();
        LocalDateTime end = to.plusDays(1).atStartOfDay();
        Map<LocalDate, Long> members = counts("nguoi_dung", "thoi_diem_tao", "AND vai_tro = 'MEMBER'", start, end);
        Map<LocalDate, Long> listings = counts("tin_cho_thue", "thoi_diem_tao", "", start, end);
        Map<LocalDate, Long> contracts = counts("hop_dong_thue", "thoi_diem_tao", "", start, end);
        Map<LocalDate, BigDecimal> revenue = new HashMap<>();
        List<Map<String, Object>> payments = jdbc.queryForList("""
            SELECT CAST(thoi_diem_giao_dich AS date) AS day, SUM(so_tien) AS revenue
            FROM giao_dich_thanh_toan WHERE thoi_diem_giao_dich >= ? AND thoi_diem_giao_dich < ?
            AND trang_thai = 'SUCCESS' GROUP BY CAST(thoi_diem_giao_dich AS date)
            """, start, end);
        for (Map<String, Object> row : payments) {
            LocalDate day = ((java.sql.Date) row.get("day")).toLocalDate();
            revenue.put(day, (BigDecimal) row.get("revenue"));
        }
        long memberTotal = 0, listingTotal = 0, contractTotal = 0;
        BigDecimal revenueTotal = BigDecimal.ZERO;
        List<ReportResponse.Daily> daily = new ArrayList<>();
        for (LocalDate day = from; !day.isAfter(to); day = day.plusDays(1)) {
            long m = members.getOrDefault(day, 0L);
            long l = listings.getOrDefault(day, 0L);
            long c = contracts.getOrDefault(day, 0L);
            BigDecimal r = revenue.getOrDefault(day, BigDecimal.ZERO);
            memberTotal += m; listingTotal += l; contractTotal += c; revenueTotal = revenueTotal.add(r);
            daily.add(new ReportResponse.Daily(day, m, l, c, r));
        }
        Long successful = jdbc.queryForObject("SELECT COUNT(*) FROM giao_dich_thanh_toan WHERE thoi_diem_giao_dich >= ? AND thoi_diem_giao_dich < ? AND trang_thai = 'SUCCESS'", Long.class, start, end);
        return new ReportResponse(from, to, LocalDateTime.now(), memberTotal, listingTotal, contractTotal,
            revenueTotal, successful, daily, statuses("tin_cho_thue", "trang_thai_kiem_duyet", start, end), statuses("hop_dong_thue", "trang_thai", start, end));
    }

    private Map<LocalDate, Long> counts(String table, String column, String filter, LocalDateTime start, LocalDateTime end) {
        String sql = "SELECT CAST(" + column + " AS date) AS day, COUNT(*) AS total FROM " + table
            + " WHERE " + column + " >= ? AND " + column + " < ? " + filter + " GROUP BY CAST(" + column + " AS date)";
        Map<LocalDate, Long> result = new HashMap<>();
        for (Map<String, Object> row : jdbc.queryForList(sql, start, end)) {
            result.put(((java.sql.Date) row.get("day")).toLocalDate(), ((Number) row.get("total")).longValue());
        }
        return result;
    }

    private List<ReportResponse.Breakdown> statuses(String table, String column, LocalDateTime start, LocalDateTime end) {
        List<ReportResponse.Breakdown> result = new ArrayList<>();
        String sql = "SELECT " + column + " AS trang_thai, COUNT(*) AS total FROM " + table
            + " WHERE thoi_diem_tao >= ? AND thoi_diem_tao < ? GROUP BY " + column + " ORDER BY " + column;
        for (Map<String, Object> row : jdbc.queryForList(sql, start, end)) {
            result.add(new ReportResponse.Breakdown((String) row.get("trang_thai"), ((Number) row.get("total")).longValue()));
        }
        return result;
    }
}
