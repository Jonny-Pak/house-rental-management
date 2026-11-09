package com.rental.core.excel;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.springframework.http.HttpStatus;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ExcelWorkbook {
    static {
        org.apache.poi.openxml4j.util.ZipSecureFile.setMaxEntrySize(16 * 1024 * 1024);
        org.apache.poi.openxml4j.util.ZipSecureFile.setMaxFileCount(128);
    }

    private ExcelWorkbook() {}

    public static void checkFile(MultipartFile file) {
        String name = file.getOriginalFilename();
        if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024 || name == null || !name.toLowerCase(java.util.Locale.ROOT).endsWith(".xlsx")) {
            throw bad("Chọn file .xlsx không rỗng, dung lượng tối đa 5 MB.");
        }
    }

    public static Sheet checkSheet(Workbook book, String name, List<String> headers) {
        Sheet sheet = book.getSheet(name);
        if (sheet == null || sheet.getRow(0) == null) throw bad("Thiếu sheet " + name + " hoặc hàng tiêu đề. Hãy tải lại file mẫu.");
        if (sheet.getLastRowNum() > 500) throw bad("Mỗi file chỉ được chứa tối đa 500 dòng dữ liệu.");
        for (int i = 0; i < headers.size(); i++) {
            if (!headers.get(i).equals(text(sheet.getRow(0), i))) throw bad("Sai cột " + (i + 1) + ": cần là “" + headers.get(i) + "”.");
        }
        return sheet;
    }

    public static String text(Row row, int column) {
        Cell cell = row.getCell(column);
        if (cell == null || cell.getCellType() == CellType.BLANK) return null;
        if (cell.getCellType() == CellType.FORMULA || cell.getCellType() == CellType.ERROR) throw new IllegalArgumentException("Cột " + (column + 1) + " không được chứa công thức hoặc lỗi Excel.");
        String value = new DataFormatter(java.util.Locale.ROOT).formatCellValue(cell).trim();
        if (cell.getCellType() == CellType.NUMERIC) value = BigDecimal.valueOf(cell.getNumericCellValue()).stripTrailingZeros().toPlainString();
        return value.isEmpty() ? null : value;
    }

    public static BigDecimal number(Row row, int column) {
        String value = text(row, column);
        if (value == null) return null;
        try { return new BigDecimal(value); }
        catch (NumberFormatException e) { throw new IllegalArgumentException("Cột " + (column + 1) + " phải là số, không kèm đơn vị."); }
    }

    public static Long id(Row row, int column) {
        BigDecimal value = number(row, column);
        try { return value == null ? null : value.longValueExact(); }
        catch (ArithmeticException e) { throw new IllegalArgumentException("Cột " + (column + 1) + " phải là số nguyên."); }
    }

    public static LocalDate date(Row row, int column) {
        Cell cell = row.getCell(column);
        if (cell != null && cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) return cell.getLocalDateTimeCellValue().toLocalDate();
        String value = text(row, column);
        try { return value == null ? null : LocalDate.parse(value); }
        catch (java.time.format.DateTimeParseException e) { throw new IllegalArgumentException("Cột " + (column + 1) + " phải là ngày yyyy-MM-dd."); }
    }

    public static boolean empty(Row row, int columns) {
        if (row == null) return true;
        for (int i = 0; i < columns; i++) {
            Cell c = row.getCell(i);
            if (c != null && c.getCellType() != CellType.BLANK && !(c.getCellType() == CellType.STRING && c.getStringCellValue().isBlank())) return false;
        }
        return true;
    }

    public static void writeRow(Row row, List<?> values) {
        for (int i = 0; i < values.size(); i++) {
            Object value = values.get(i);
            Cell cell = row.createCell(i);
            if (value instanceof Number n) cell.setCellValue(n.doubleValue());
            else if (value instanceof Boolean b) cell.setCellValue(b);
            else if (value != null) cell.setCellValue(value.toString());
        }
    }

    public static void style(Workbook book, Sheet sheet, int columns) {
        Font font = book.createFont(); font.setBold(true); font.setColor(IndexedColors.WHITE.getIndex());
        CellStyle header = book.createCellStyle(); header.setFont(font);
        header.setFillForegroundColor(IndexedColors.DARK_TEAL.getIndex()); header.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        for (int i = 0; i < columns; i++) {
            sheet.getRow(0).getCell(i).setCellStyle(header);
            sheet.setColumnWidth(i, 25 * 256);
        }
        sheet.getRow(0).setHeightInPoints(25);
        sheet.createFreezePane(0, 1);
        sheet.setAutoFilter(new CellRangeAddress(0, Math.max(1, sheet.getLastRowNum()), 0, columns - 1));
    }

    public static ResponseStatusException bad(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }
}
