package com.rental.modules.report;

import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Component;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

@Component
public class ReportExcel {
    public byte[] write(ReportResponse report) {
        try (XSSFWorkbook book = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Sheet summary = book.createSheet("Tổng quan");
            row(summary, 0, "Báo cáo từ", report.from().toString(), "đến", report.to().toString());
            row(summary, 1, "Tạo lúc", report.generatedAt().toString());
            row(summary, 2, "Member mới", report.members());
            row(summary, 3, "Tin tạo mới", report.listings());
            row(summary, 4, "Hợp đồng tạo mới", report.contracts());
            row(summary, 5, "Doanh thu dịch vụ (VND)", report.revenue());
            row(summary, 6, "Giao dịch thành công", report.successfulPayments());
            row(summary, 8, "Doanh thu tính giao dịch SUCCESS theo ngày tạo giao dịch; không gồm tiền thuê/cọc.");
            row(summary, 9, "Trạng thái là trạng thái hiện tại của bản ghi tạo trong khoảng đã chọn; không phải lịch sử tại ngày kết thúc.");
            Sheet daily = book.createSheet("Theo ngày");
            row(daily, 0, "Ngày", "Member mới", "Tin mới", "Hợp đồng mới", "Doanh thu dịch vụ (VND)");
            int index = 1;
            for (ReportResponse.Daily day : report.daily()) {
                row(daily, index++, day.date().toString(), day.members(), day.listings(), day.contracts(), day.revenue());
            }
            Sheet statuses = book.createSheet("Trạng thái");
            row(statuses, 0, "Nhóm", "Trạng thái hiện tại", "Số lượng");
            index = 1;
            for (ReportResponse.Breakdown item : report.listingStatuses()) row(statuses, index++, "Tin đăng", item.status(), item.count());
            for (ReportResponse.Breakdown item : report.contractStatuses()) row(statuses, index++, "Hợp đồng", item.status(), item.count());
            for (Sheet sheet : book) {
                sheet.createFreezePane(0, 1);
                for (int i = 0; i < 5; i++) sheet.setColumnWidth(i, 24 * 256);
                Font font = book.createFont(); font.setBold(true);
                CellStyle header = book.createCellStyle(); header.setFont(font);
                for (Cell cell : sheet.getRow(0)) cell.setCellStyle(header);
            }
            book.write(output);
            return output.toByteArray();
        } catch (IOException error) { throw new IllegalStateException("Không tạo được báo cáo Excel.", error); }
    }
    private void row(Sheet sheet, int index, Object... values) {
        Row row = sheet.createRow(index);
        for (int i = 0; i < values.length; i++) {
            Cell cell = row.createCell(i);
            if (values[i] instanceof Number number) cell.setCellValue(number.doubleValue());
            else cell.setCellValue(values[i].toString());
        }
    }
}
