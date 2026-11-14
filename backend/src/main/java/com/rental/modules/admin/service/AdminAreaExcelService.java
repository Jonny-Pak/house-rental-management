package com.rental.modules.admin.service;

import com.rental.core.excel.ExcelImportResult;
import com.rental.core.excel.ExcelWorkbook;
import com.rental.modules.admin.dto.request.AdminAreaRequest;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
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
public class AdminAreaExcelService {
    private static final List<String> HEADERS = List.of("Tên khu vực", "Cấp hành chính", "Mã khu vực", "Mã đơn vị cấp trên (để trống với tỉnh/thành)");
    private static final Set<String> TYPES = Set.of("PROVINCE", "WARD", "COMMUNE", "SPECIAL");
    private final AdministrativeAreaRepository areas;
    private final AdminAreaService adminAreas;

    public AdminAreaExcelService(AdministrativeAreaRepository areas, AdminAreaService adminAreas) {
        this.areas = areas;
        this.adminAreas = adminAreas;
    }

    public byte[] template() { return workbook(List.of(), true); }
    public byte[] export() {
        Map<Long, String> parents = new HashMap<>();
        for (var area : areas.findAll()) if (area.getParent() != null) parents.put(area.getAreaId(), area.getParent().getCode());
        List<List<Object>> rows = areas.findAll().stream().map(area -> List.<Object>of(area.getAreaName(), area.getAreaType(), area.getCode(), parents.getOrDefault(area.getAreaId(), ""))).toList();
        return workbook(rows, false);
    }
    public ExcelImportResult preview(MultipartFile file) { return read(file).result(0); }
    @Transactional
    public ExcelImportResult importFile(MultipartFile file) {
        Parsed parsed = read(file);
        if (!parsed.errors.isEmpty()) return parsed.result(0);
        Map<String, Long> ids = new HashMap<>();
        for (var area : areas.findAll()) ids.put(area.getCode().toUpperCase(Locale.ROOT), area.getAreaId());
        for (AreaRow row : parsed.areas) {
            Long parentId = row.parentCode() == null ? null : ids.get(row.parentCode());
            var saved = adminAreas.create(new AdminAreaRequest(row.name(), row.type(), row.code(), parentId));
            ids.put(row.code(), saved.id());
        }
        return parsed.result(parsed.areas.size());
    }

    private Parsed read(MultipartFile file) {
        ExcelWorkbook.checkFile(file);
        Parsed parsed = new Parsed();
        Map<String, ExistingArea> codes = new HashMap<>();
        for (var area : areas.findAll()) codes.put(area.getCode().toUpperCase(Locale.ROOT), new ExistingArea(area.getAreaName(), area.getAreaType(), area.getParent() == null ? null : area.getParent().getCode().toUpperCase(Locale.ROOT), area.isAvailable()));
        Set<String> names = new HashSet<>();
        for (var area : areas.findAll()) names.add(key(area.getAreaName(), area.getParent() == null ? "" : area.getParent().getCode()));
        try (var input = file.getInputStream(); var book = new XSSFWorkbook(input)) {
            Sheet sheet = ExcelWorkbook.checkSheet(book, "KhuVuc", HEADERS);
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (ExcelWorkbook.empty(row, HEADERS.size())) continue;
                parsed.total++;
                try {
                    String name = required(row, 0, 150);
                    String type = required(row, 1, 20).toUpperCase(Locale.ROOT);
                    String code = required(row, 2, 20).toUpperCase(Locale.ROOT);
                    String parentCode = ExcelWorkbook.text(row, 3);
                    if (!TYPES.contains(type)) throw new IllegalArgumentException("Cấp hành chính chỉ nhận PROVINCE, WARD, COMMUNE hoặc SPECIAL; không hỗ trợ tạo mới quận/huyện cũ.");
                    if (!code.matches("[A-Z0-9_-]{1,20}")) throw new IllegalArgumentException("Mã khu vực chỉ gồm chữ, số, dấu gạch ngang hoặc gạch dưới (tối đa 20 ký tự).");
                    if (codes.containsKey(code)) throw new IllegalArgumentException("Mã khu vực đã tồn tại hoặc bị lặp trong file.");
                    if ("PROVINCE".equals(type)) {
                        if (parentCode != null) throw new IllegalArgumentException("Tỉnh/thành không có mã đơn vị cấp trên.");
                    } else {
                        if (parentCode == null) throw new IllegalArgumentException("Cần nhập mã đơn vị cấp trên.");
                        parentCode = parentCode.toUpperCase(Locale.ROOT);
                        ExistingArea parent = codes.get(parentCode);
                        if (parent == null) throw new IllegalArgumentException("Không tìm thấy đơn vị cấp trên theo mã “" + parentCode + "”. Hãy đặt dòng cấp trên trước.");
                        if (!parent.active()) throw new IllegalArgumentException("Đơn vị cấp trên đã ngừng sử dụng.");
                        if (!("PROVINCE".equals(parent.type()) || ("WARD".equals(type) && "DISTRICT".equals(parent.type())))) throw new IllegalArgumentException("Cấp của đơn vị cấp trên không phù hợp.");
                    }
                    if (!names.add(key(name, parentCode == null ? "" : parentCode))) throw new IllegalArgumentException("Tên khu vực bị trùng trong cùng đơn vị cấp trên.");
                    codes.put(code, new ExistingArea(name, type, parentCode, true));
                    parsed.areas.add(new AreaRow(name, type, code, parentCode));
                    parsed.rows.add(new ExcelImportResult.RowPreview(i + 1, name, type + " · " + code + (parentCode == null ? "" : " · cấp trên " + parentCode)));
                } catch (IllegalArgumentException ex) { parsed.errors.add(new ExcelImportResult.RowError(i + 1, ex.getMessage())); }
            }
            if (parsed.total == 0) throw ExcelWorkbook.bad("File chưa có khu vực để nhập.");
            return parsed;
        } catch (ResponseStatusException ex) { throw ex; }
        catch (Exception ex) { throw ExcelWorkbook.bad("Không đọc được Excel. Hãy dùng file mẫu .xlsx và không dùng công thức."); }
    }

    private String required(Row row, int column, int max) {
        String value = ExcelWorkbook.text(row, column);
        if (value == null || value.isBlank() || value.length() > max) throw new IllegalArgumentException("Cột " + (column + 1) + " là bắt buộc (tối đa " + max + " ký tự).");
        return value.trim();
    }
    private String key(String name, String parent) { return name.trim().toLowerCase(Locale.ROOT) + "|" + parent.trim().toUpperCase(Locale.ROOT); }
    private byte[] workbook(List<List<Object>> rows, boolean template) {
        try (var book = new XSSFWorkbook(); var output = new ByteArrayOutputStream()) {
            Sheet sheet = book.createSheet("KhuVuc"); ExcelWorkbook.writeRow(sheet.createRow(0), HEADERS);
            for (var row : rows) ExcelWorkbook.writeRow(sheet.createRow(sheet.getLastRowNum() + 1), row);
            ExcelWorkbook.style(book, sheet, HEADERS.size());
            if (template) {
                Sheet help = book.createSheet("HuongDan");
                List<String> notes = List.of("Mỗi dòng tạo một khu vực mới; không cập nhật khu vực đã có.", "Cấp hành chính: PROVINCE, WARD, COMMUNE hoặc SPECIAL. Quận/huyện cũ không thể tạo mới.", "Tỉnh/thành để trống mã đơn vị cấp trên. Phường/xã/đặc khu nhập mã tỉnh hoặc huyện cũ; dòng cấp trên phải nằm trước.", "Mã khu vực phải duy nhất. Tối đa 500 dòng, file .xlsx tối đa 5 MB. Nếu có dòng lỗi, toàn bộ file sẽ không được nhập.");
                for (int i = 0; i < notes.size(); i++) help.createRow(i).createCell(0).setCellValue(notes.get(i)); help.setColumnWidth(0, 110 * 256);
            }
            book.write(output); return output.toByteArray();
        } catch (Exception ex) { throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Không tạo được file Excel."); }
    }
    private record AreaRow(String name, String type, String code, String parentCode) {}
    private record ExistingArea(String name, String type, String parentCode, boolean active) {}
    private static class Parsed {
        int total; final List<AreaRow> areas = new ArrayList<>(); final List<ExcelImportResult.RowPreview> rows = new ArrayList<>(); final List<ExcelImportResult.RowError> errors = new ArrayList<>();
        ExcelImportResult result(int imported) { return new ExcelImportResult(total, imported, rows, errors); }
    }
}
