package com.rental.modules.amenity.service;

import com.rental.core.excel.ExcelImportResult;
import com.rental.core.excel.ExcelWorkbook;
import com.rental.modules.amenity.dto.SaveAmenityRequest;
import com.rental.modules.amenity.repository.AmenityRepository;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.io.ByteArrayOutputStream;
import java.util.*;

@Service
@Transactional(readOnly = true)
public class AmenityExcelService {
    private static final List<String> HEADERS = List.of("Tên nội thất/tiện ích", "Nhóm (FURNITURE/UTILITY)", "Mô tả", "Đang sử dụng (TRUE/FALSE)");
    private final AmenityRepository repository;
    private final AmenityService amenities;
    public AmenityExcelService(AmenityRepository repository, AmenityService amenities) { this.repository = repository; this.amenities = amenities; }

    public byte[] template() { return workbook(List.of(), true); }
    public byte[] export() {
        List<List<Object>> rows = repository.findAll().stream().map(item -> List.<Object>of(item.getName(), item.getCategory(), item.getDescription(), item.isActive() ? "TRUE" : "FALSE")).toList();
        return workbook(rows, false);
    }
    public ExcelImportResult preview(MultipartFile file) { return read(file).result(0); }
    @Transactional
    public ExcelImportResult importFile(MultipartFile file) {
        Parsed parsed = read(file);
        if (!parsed.errors.isEmpty()) return parsed.result(0);
        for (AmenityRow row : parsed.amenities) amenities.create(new SaveAmenityRequest(row.name(), row.category(), row.description(), row.active(), null));
        return parsed.result(parsed.amenities.size());
    }

    private Parsed read(MultipartFile file) {
        ExcelWorkbook.checkFile(file); Parsed parsed = new Parsed();
        Set<String> known = new HashSet<>();
        for (var item : repository.findAll()) known.add(key(item.getCategory(), item.getName()));
        try (var input = file.getInputStream(); var book = new XSSFWorkbook(input)) {
            Sheet sheet = ExcelWorkbook.checkSheet(book, "NoiThatTienIch", HEADERS);
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i); if (ExcelWorkbook.empty(row, HEADERS.size())) continue; parsed.total++;
                try {
                    String name = required(row, 0, 100), category = required(row, 1, 20).toUpperCase(Locale.ROOT);
                    String description = ExcelWorkbook.text(row, 2); String enabledText = ExcelWorkbook.text(row, 3);
                    if (!"FURNITURE".equals(category) && !"UTILITY".equals(category)) throw new IllegalArgumentException("Nhóm phải là FURNITURE hoặc UTILITY.");
                    if (description != null && description.length() > 255) throw new IllegalArgumentException("Mô tả tối đa 255 ký tự.");
                    boolean active = enabledText == null || "TRUE".equalsIgnoreCase(enabledText) || "1".equals(enabledText);
                    if (enabledText != null && !active && !"FALSE".equalsIgnoreCase(enabledText) && !"0".equals(enabledText)) throw new IllegalArgumentException("Trạng thái phải là TRUE hoặc FALSE.");
                    if (!known.add(key(category, name))) throw new IllegalArgumentException("Tên đã tồn tại hoặc bị lặp trong cùng nhóm.");
                    parsed.amenities.add(new AmenityRow(name, category, description == null ? "" : description, active));
                    parsed.rows.add(new ExcelImportResult.RowPreview(i + 1, name, ("FURNITURE".equals(category) ? "Nội thất" : "Tiện ích") + (description == null ? "" : " · " + description)));
                } catch (IllegalArgumentException ex) { parsed.errors.add(new ExcelImportResult.RowError(i + 1, ex.getMessage())); }
            }
            if (parsed.total == 0) throw ExcelWorkbook.bad("File chưa có nội thất/tiện ích để nhập.");
            return parsed;
        } catch (ResponseStatusException ex) { throw ex; }
        catch (Exception ex) { throw ExcelWorkbook.bad("Không đọc được Excel. Hãy dùng file mẫu .xlsx và không dùng công thức."); }
    }
    private String required(Row row, int column, int max) {
        String value = ExcelWorkbook.text(row, column);
        if (value == null || value.isBlank() || value.length() > max) throw new IllegalArgumentException("Cột " + (column + 1) + " là bắt buộc (tối đa " + max + " ký tự).");
        return value.trim();
    }
    private String key(String category, String name) { return category.toUpperCase(Locale.ROOT) + "|" + name.trim().toLowerCase(Locale.ROOT); }
    private byte[] workbook(List<List<Object>> rows, boolean template) {
        try (var book = new XSSFWorkbook(); var output = new ByteArrayOutputStream()) {
            Sheet sheet = book.createSheet("NoiThatTienIch"); ExcelWorkbook.writeRow(sheet.createRow(0), HEADERS);
            for (var row : rows) ExcelWorkbook.writeRow(sheet.createRow(sheet.getLastRowNum() + 1), row);
            ExcelWorkbook.style(book, sheet, HEADERS.size());
            if (template) {
                Sheet help = book.createSheet("HuongDan");
                List<String> notes = List.of("Mỗi dòng tạo một danh mục mới; không cập nhật mục đã có.", "Nhóm dùng FURNITURE cho nội thất, UTILITY cho tiện ích.", "Trạng thái dùng TRUE hoặc FALSE; để trống sẽ mặc định TRUE.", "Tên phải duy nhất trong cùng nhóm. Tối đa 500 dòng, file .xlsx tối đa 5 MB. Nếu có dòng lỗi, toàn bộ file sẽ không được nhập.");
                for (int i = 0; i < notes.size(); i++) help.createRow(i).createCell(0).setCellValue(notes.get(i)); help.setColumnWidth(0, 110 * 256);
            }
            book.write(output); return output.toByteArray();
        } catch (Exception ex) { throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Không tạo được file Excel."); }
    }
    private record AmenityRow(String name, String category, String description, boolean active) {}
    private static class Parsed {
        int total; final List<AmenityRow> amenities = new ArrayList<>(); final List<ExcelImportResult.RowPreview> rows = new ArrayList<>(); final List<ExcelImportResult.RowError> errors = new ArrayList<>();
        ExcelImportResult result(int imported) { return new ExcelImportResult(total, imported, rows, errors); }
    }
}
