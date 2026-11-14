package com.rental.modules.admin.service;

import com.rental.core.excel.ExcelImportResult;
import com.rental.core.excel.ExcelWorkbook;
import com.rental.modules.admin.dto.request.AdminCreateUserRequest;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.repository.UserRepository;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.ByteArrayOutputStream;
import java.util.*;
import java.util.regex.Pattern;

@Service
@Transactional(readOnly = true)
public class AdminUserExcelService {
    private static final List<String> HEADERS = List.of("Họ và tên", "Email", "Số điện thoại (không bắt buộc)", "Mật khẩu tạm thời");
    private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    private final UserRepository users;
    private final AdminCreateUserService creation;

    public AdminUserExcelService(UserRepository users, AdminCreateUserService creation) {
        this.users = users;
        this.creation = creation;
    }

    public byte[] template() { return workbook(List.of(), true); }

    public byte[] export() {
        return workbook(users.findAll().stream().map(user -> List.of(
            value(user.getFullName()), value(user.getEmail()), value(user.getPhoneNumber()),
            user.getRole().name(), user.getStatus().name(), Boolean.TRUE.equals(user.getIsVerified()) ? "TRUE" : "FALSE"
        )).toList(), false);
    }

    public ExcelImportResult preview(MultipartFile file) { return read(file).result(0); }

    @Transactional
    public ExcelImportResult importFile(MultipartFile file) {
        Parsed parsed = read(file);
        if (!parsed.errors.isEmpty()) return parsed.result(0);
        int imported = 0;
        for (UserRow row : parsed.users) {
            creation.create(new AdminCreateUserRequest(row.name(), row.email(), row.phone(), row.password(), Role.MEMBER));
            imported++;
        }
        return parsed.result(imported);
    }

    private Parsed read(MultipartFile file) {
        ExcelWorkbook.checkFile(file);
        Parsed parsed = new Parsed();
        Set<String> emails = new HashSet<>();
        Set<String> phones = new HashSet<>();
        try (var input = file.getInputStream(); var book = new XSSFWorkbook(input)) {
            Sheet sheet = ExcelWorkbook.checkSheet(book, "NguoiDung", HEADERS);
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (ExcelWorkbook.empty(row, HEADERS.size())) continue;
                parsed.total++;
                try {
                    String name = required(row, 0, "Họ và tên", 150);
                    String email = required(row, 1, "Email", 150).toLowerCase(Locale.ROOT);
                    String phone = ExcelWorkbook.text(row, 2);
                    String password = required(row, 3, "Mật khẩu tạm thời", 72);
                    if (!EMAIL.matcher(email).matches()) throw new IllegalArgumentException("Email không hợp lệ.");
                    if (password.length() < 8 || password.getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72) throw new IllegalArgumentException("Mật khẩu tạm thời phải dài từ 8 đến 72 byte UTF-8.");
                    if (phone != null && !phone.matches("[0-9+][0-9]{8,14}")) throw new IllegalArgumentException("Số điện thoại không hợp lệ.");
                    if (users.existsByEmailIgnoreCase(email) || !emails.add(email)) throw new IllegalArgumentException("Email đã tồn tại hoặc bị lặp trong file.");
                    if (phone != null && (users.findByPhoneNumber(phone).isPresent() || !phones.add(phone))) throw new IllegalArgumentException("Số điện thoại đã tồn tại hoặc bị lặp trong file.");
                    parsed.users.add(new UserRow(name, email, phone, password));
                    parsed.rows.add(new ExcelImportResult.RowPreview(i + 1, email, name + (phone == null ? "" : " · " + phone)));
                } catch (IllegalArgumentException ex) {
                    parsed.errors.add(new ExcelImportResult.RowError(i + 1, ex.getMessage()));
                }
            }
            if (parsed.total == 0) throw ExcelWorkbook.bad("File chưa có người dùng để nhập.");
            return parsed;
        } catch (ResponseStatusException ex) { throw ex; }
        catch (Exception ex) { throw ExcelWorkbook.bad("Không đọc được Excel. Hãy dùng file mẫu .xlsx và không dùng công thức."); }
    }

    private String required(Row row, int col, String label, int max) {
        String value = ExcelWorkbook.text(row, col);
        if (value == null || value.isBlank() || value.length() > max) throw new IllegalArgumentException(label + " là bắt buộc (tối đa " + max + " ký tự).");
        return value.trim();
    }

    private byte[] workbook(List<List<Object>> rows, boolean template) {
        try (var book = new XSSFWorkbook(); var output = new ByteArrayOutputStream()) {
            Sheet sheet = book.createSheet("NguoiDung");
            List<String> headers = template ? HEADERS : List.of("Họ và tên", "Email", "Số điện thoại", "Vai trò", "Trạng thái", "Đã xác thực");
            ExcelWorkbook.writeRow(sheet.createRow(0), headers);
            for (List<Object> row : rows) ExcelWorkbook.writeRow(sheet.createRow(sheet.getLastRowNum() + 1), row);
            ExcelWorkbook.style(book, sheet, headers.size());
            if (template) {
                Sheet help = book.createSheet("HuongDan");
                List<String> notes = List.of("Mỗi dòng tạo một tài khoản Member mới. Không hỗ trợ nhập Admin hoặc cập nhật tài khoản hiện có.", "Bắt buộc: Họ và tên, Email, Mật khẩu tạm thời. Số điện thoại có thể để trống.", "Mật khẩu tạm thời phải dài tối thiểu 8 ký tự và tối đa 72 byte UTF-8. Tài khoản cần xác thực OTP qua email.", "Không chia sẻ công khai file chứa mật khẩu. Mật khẩu không xuất hiện trong file xuất.", "Nếu có dòng lỗi, toàn bộ file sẽ không được nhập. Tối đa 500 dòng, file .xlsx tối đa 5 MB.");
                for (int i = 0; i < notes.size(); i++) help.createRow(i).createCell(0).setCellValue(notes.get(i));
                help.setColumnWidth(0, 110 * 256);
            }
            book.write(output);
            return output.toByteArray();
        } catch (Exception ex) { throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Không tạo được file Excel."); }
    }

    private Object value(Object value) { return value == null ? "" : value; }
    private record UserRow(String name, String email, String phone, String password) {}
    private static class Parsed {
        int total; final List<UserRow> users = new ArrayList<>();
        final List<ExcelImportResult.RowPreview> rows = new ArrayList<>();
        final List<ExcelImportResult.RowError> errors = new ArrayList<>();
        ExcelImportResult result(int imported) { return new ExcelImportResult(total, imported, rows, errors); }
    }
}
