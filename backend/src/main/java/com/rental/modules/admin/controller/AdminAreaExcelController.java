package com.rental.modules.admin.controller;

import com.rental.core.excel.ExcelImportResult;
import com.rental.modules.admin.service.AdminAreaExcelService;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/admin/areas/excel")
@PreAuthorize("hasRole('ADMIN')")
public class AdminAreaExcelController {
    private final AdminAreaExcelService excel;
    public AdminAreaExcelController(AdminAreaExcelService excel) { this.excel = excel; }
    @GetMapping("/template") public ResponseEntity<byte[]> template() { return download(excel.template(), "mau-khu-vuc.xlsx"); }
    @GetMapping("/export") public ResponseEntity<byte[]> export() { return download(excel.export(), "khu-vuc-hanh-chinh.xlsx"); }
    @PostMapping("/preview") public ExcelImportResult preview(@RequestParam("file") MultipartFile file) { return excel.preview(file); }
    @PostMapping("/import") public ExcelImportResult importFile(@RequestParam("file") MultipartFile file) { return excel.importFile(file); }
    private ResponseEntity<byte[]> download(byte[] bytes, String name) {
        return ResponseEntity.ok().contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + name + "\"").body(bytes);
    }
}
