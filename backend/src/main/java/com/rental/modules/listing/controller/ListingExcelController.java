package com.rental.modules.listing.controller;

import com.rental.core.excel.ExcelImportResult;
import com.rental.core.security.CustomUserDetails;
import com.rental.modules.listing.service.ListingExcelService;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/listings/excel")
public class ListingExcelController {
    private final ListingExcelService excel;
    public ListingExcelController(ListingExcelService excel) { this.excel = excel; }

    @GetMapping("/template")
    public ResponseEntity<byte[]> template() { return download(excel.template(), "mau-tin-dang.xlsx"); }

    @GetMapping("/export")
    public ResponseEntity<byte[]> export(@AuthenticationPrincipal CustomUserDetails user) {
        return download(excel.exportListings(user.getUser().getUserId()), "tin-dang.xlsx");
    }

    @PostMapping("/preview")
    public ExcelImportResult preview(@AuthenticationPrincipal CustomUserDetails user, @RequestParam("file") MultipartFile file) {
        return excel.preview(user.getUser().getUserId(), file);
    }

    @PostMapping("/import")
    public ExcelImportResult importFile(@AuthenticationPrincipal CustomUserDetails user, @RequestParam("file") MultipartFile file) {
        return excel.importListings(user.getUser().getUserId(), file);
    }

    private ResponseEntity<byte[]> download(byte[] bytes, String name) {
        return ResponseEntity.ok().contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + name + "\"").body(bytes);
    }
}
