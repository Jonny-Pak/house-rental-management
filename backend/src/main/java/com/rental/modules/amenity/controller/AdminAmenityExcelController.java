package com.rental.modules.amenity.controller;

import com.rental.core.excel.ExcelImportResult;
import com.rental.modules.amenity.service.AmenityExcelService;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/admin/amenities/excel")
@PreAuthorize("hasRole('ADMIN')")
public class AdminAmenityExcelController {
    private final AmenityExcelService excel;
    public AdminAmenityExcelController(AmenityExcelService excel) { this.excel = excel; }
    @GetMapping("/template") public ResponseEntity<byte[]> template() { return download(excel.template(), "mau-noi-that-tien-ich.xlsx"); }
    @GetMapping("/export") public ResponseEntity<byte[]> export() { return download(excel.export(), "noi-that-tien-ich.xlsx"); }
    @PostMapping("/preview") public ExcelImportResult preview(@RequestParam("file") MultipartFile file) { return excel.preview(file); }
    @PostMapping("/import") public ExcelImportResult importFile(@RequestParam("file") MultipartFile file) { return excel.importFile(file); }
    private ResponseEntity<byte[]> download(byte[] bytes, String name) {
        return ResponseEntity.ok().contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + name + "\"").body(bytes);
    }
}
