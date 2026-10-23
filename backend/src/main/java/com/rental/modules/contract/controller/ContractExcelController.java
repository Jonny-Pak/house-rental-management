package com.rental.modules.contract.controller;

import com.rental.core.excel.ExcelImportResult;
import com.rental.core.security.CustomUserDetails;
import com.rental.modules.contract.service.ContractExcelService;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/contracts/excel")
public class ContractExcelController {
    private final ContractExcelService excel;
    public ContractExcelController(ContractExcelService excel) { this.excel = excel; }

    @GetMapping("/template")
    public ResponseEntity<byte[]> template(@AuthenticationPrincipal CustomUserDetails user) {
        return download(excel.template(user.getUser().getUserId()), "mau-hop-dong.xlsx");
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> export(@AuthenticationPrincipal CustomUserDetails user) { return download(excel.exportContracts(user.getUsername()), "hop-dong.xlsx"); }

    @PostMapping("/preview")
    public ExcelImportResult preview(@AuthenticationPrincipal CustomUserDetails user, @RequestParam("file") MultipartFile file) {
        return excel.preview(user.getUsername(), user.getUser().getUserId(), file);
    }

    @PostMapping("/import")
    public ExcelImportResult importFile(@AuthenticationPrincipal CustomUserDetails user, @RequestParam("file") MultipartFile file) {
        return excel.importContracts(user.getUsername(), user.getUser().getUserId(), file);
    }

    private ResponseEntity<byte[]> download(byte[] bytes, String name) {
        return ResponseEntity.ok().contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + name + "\"").body(bytes);
    }
}
