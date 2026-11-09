package com.rental.modules.report;

import com.rental.core.dto.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.*;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/admin/reports")
@PreAuthorize("hasRole('ADMIN')")
public class ReportController {
    private final ReportService service;
    private final ReportExcel excel;
    public ReportController(ReportService service, ReportExcel excel) { this.service = service; this.excel = excel; }
    @GetMapping
    public ApiResponse<ReportResponse> report(
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.success("Thống kê từ dữ liệu hệ thống.", service.report(from, to));
    }
    @GetMapping("/export")
    public ResponseEntity<byte[]> export(
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        byte[] bytes = excel.write(service.report(from, to));
        return ResponseEntity.ok().contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=report-" + from + "-" + to + ".xlsx")
            .header(HttpHeaders.CACHE_CONTROL, "no-store").body(bytes);
    }
}
