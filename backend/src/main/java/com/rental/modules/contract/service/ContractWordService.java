package com.rental.modules.contract.service;

import com.rental.modules.contract.domain.entity.Contract;
import com.rental.modules.contract.dto.request.ContractDetails;
import org.apache.poi.xwpf.usermodel.*;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class ContractWordService {
    public record Generated(byte[] bytes, String text) {}

    public Generated generate(Contract contract, ContractDetails details) {
        String template = "ROOM".equals(contract.getContractType())
                ? "contracts/templates/room-rental-template.docx"
                : "contracts/templates/house-rental-template.docx";
        try (var input = new ClassPathResource(template).getInputStream();
             var document = new XWPFDocument(input);
             var output = new ByteArrayOutputStream()) {
            fill(document, contract, details);
            document.write(output);
            return new Generated(output.toByteArray(), extractText(document));
        } catch (IOException exception) {
            throw new IllegalStateException("Không tạo được hợp đồng Word từ mẫu.", exception);
        }
    }

    private void fill(XWPFDocument doc, Contract c, ContractDetails d) {
        boolean room = "ROOM".equals(c.getContractType());
        int[] party = {0};
        for (XWPFParagraph paragraph : paragraphs(doc)) {
            String text = paragraph.getText();
            if (text == null || text.isBlank()) continue;
            if (room && text.trim().matches("[.…\\.\\s]+")) {
                setText(paragraph, "");
                continue;
            }
            String replacement = room ? roomLine(text, c, d, party) : houseLine(text, c, d, party);
            if (replacement != null && !replacement.equals(text)) setText(paragraph, replacement);
        }
    }

    private String roomLine(String s, Contract c, ContractDetails d, int[] party) {
        s = s.trim();
        if (s.startsWith("Hôm nay ngày")) return "Hôm nay " + longDate(parseDate(d.getSigningDate(), c.getStartDate())) + "; tại địa chỉ: " + text(d.getSigningPlace()) + ".";
        if (s.startsWith("Ông/bà:")) {
            boolean landlord = party[0]++ == 0;
            return "Ông/bà: " + (landlord ? text(d.getLandlordName()) : text(d.getTenantName()))
                    + "; Sinh ngày: " + text(landlord ? d.getLandlordBirthDate() : d.getTenantBirthDate());
        }
        if (s.startsWith("Nơi đăng ký HK")) return "Nơi đăng ký HK thường trú: " + (party[0] <= 1 ? text(d.getLandlordAddress()) : text(d.getTenantAddress()));
        if (s.startsWith("CMND số:") || s.startsWith("Số CMND:")) return s.substring(0, s.indexOf(':') + 1) + " " + (party[1]++ == 0 ? text(d.getLandlordIdentity()) : text(d.getTenantIdentity()));
        if (s.startsWith("Số điện thoại:")) return "Số điện thoại: " + (party[2]++ == 0 ? text(d.getLandlordPhone()) : text(d.getTenantPhone()));
        if (s.startsWith("Bên A đồng ý cho bên B thuê")) return "Bên A đồng ý cho bên B thuê 01 phòng ở tại địa chỉ: " + text(c.getListingAddress());
        if (s.startsWith("Giá thuê:")) return "Giá thuê: " + money(c.getMonthlyRent()) + " đồng/tháng";
        if (s.startsWith("Hình thức thanh toán:")) return "Hình thức thanh toán: " + text(d.getPaymentMethod());
        if (s.startsWith("Tiền điện")) return "Tiền điện: " + text(d.getElectricityTerms());
        if (s.startsWith("Tiền nước:")) return "Tiền nước: " + text(d.getWaterTerms());
        if (s.startsWith("Tiền đặt cọc:")) return "Tiền đặt cọc: " + money(c.getDepositAmount()) + " đồng. " + text(d.getDepositTerms());
        if (s.startsWith("Hợp đồng có giá trị kể từ ngày")) return "Hợp đồng có giá trị kể từ ngày " + date(c.getStartDate()) + " đến ngày " + date(c.getEndDate()) + ".";
        return null;
    }

    private String houseLine(String s, Contract c, ContractDetails d, int[] party) {
        s = s.trim();
        if (s.contains("ngày ... tháng ... năm ....") || s.startsWith("..... ngày")) return text(d.getSigningPlace()) + ", " + longDate(parseDate(d.getSigningDate(), c.getStartDate()));
        if (s.startsWith("Số ..../.....")) return "Số HĐ-" + (c.getId() == null ? "DỰ THẢO" : c.getId());
        if (s.startsWith("Căn cứ khác1")) return "Căn cứ khác: " + note(c);
        if (s.startsWith("Căn cứ các văn bản, hồ sơ pháp lý dự án:")) return "Căn cứ các văn bản, hồ sơ pháp lý dự án: Không áp dụng/không cung cấp.";
        if (s.startsWith("- Tên tổ chức, cá nhân")) return "- Tên tổ chức, cá nhân: " + (party[0]++ == 0 ? text(d.getLandlordName()) : text(d.getTenantName()));
        if (s.startsWith("- Giấy chứng nhận đăng ký doanh nghiệp")) return "- Giấy chứng nhận đăng ký doanh nghiệp/Giấy chứng nhận đăng ký đầu tư số: Không áp dụng với cá nhân.";
        if (s.startsWith("- Người đại diện theo pháp luật:")) return "- Người đại diện theo pháp luật: " + text(d.getLandlordName()) + "; Chức vụ: Chủ nhà. Thông tin giấy tờ tùy thân: " + text(d.getLandlordIdentity());
        if (s.startsWith("(Trường hợp là người đại diện theo ủy quyền")) return "Thông tin giấy tờ tùy thân chủ nhà: " + text(d.getLandlordIdentity());
        if (s.startsWith("- Thẻ căn cước công dân/hộ chiếu4 số:")) return "- Thẻ căn cước công dân/hộ chiếu số: " + text(d.getTenantIdentity());
        if (s.startsWith("- Thẻ căn cước công dân/hộ chiếu")) return "- Thẻ căn cước công dân/hộ chiếu số: " + text(d.getLandlordIdentity());
        if (s.startsWith("- Giấy chứng nhận đăng ký doanh nghiệp/Giấy chứng nhận đăng ký đầu tư số:")) return "- Giấy chứng nhận đăng ký doanh nghiệp/Giấy chứng nhận đăng ký đầu tư số: Không áp dụng với cá nhân.";
        if (s.startsWith("- Địa chỉ:")) return "- Địa chỉ: " + (party[1]++ == 0 ? text(d.getLandlordAddress()) : text(d.getTenantAddress()));
        if (s.startsWith("- Điện thoại liên hệ:")) return "- Điện thoại liên hệ: " + (party[2]++ == 0 ? text(d.getLandlordPhone()) : text(d.getTenantPhone())) + "; Fax: Không cung cấp.";
        if (s.startsWith("- Số tài khoản")) return "- Số tài khoản: Không cung cấp; Tại Ngân hàng: Không cung cấp.";
        if (s.startsWith("- Mã số thuế")) return "- Mã số thuế: Không cung cấp.";
        if (s.startsWith("1. Loại nhà ở:")) return "1. Loại nhà ở: Nhà ở riêng lẻ (theo loại tin đăng).";
        if (s.startsWith("2. Vị trí, địa điểm nhà ở:")) return "2. Vị trí, địa điểm nhà ở: " + text(c.getListingAddress());
        if (s.startsWith("3. Hiện trạng về chất lượng nhà ở:")) return "3. Hiện trạng về chất lượng nhà ở: " + text(d.getConditionDescription());
        if (s.startsWith("- Tổng diện tích sàn xây dựng nhà ở:")) return "- Tổng diện tích sàn xây dựng nhà ở: " + area(c, d) + " m² (theo tin đăng).";
        if (s.startsWith("- Tổng diện tích sử dụng đất:")) return "- Tổng diện tích sử dụng đất: Không có dữ liệu trong tin đăng.";
        if (s.startsWith("Sử dụng riêng:")) return "Sử dụng riêng: Theo hiện trạng thực tế bàn giao.";
        if (s.startsWith("Sử dụng chung (nếu có):")) return "Sử dụng chung (nếu có): Theo hiện trạng thực tế bàn giao.";
        if (s.startsWith("Mục đích sử dụng đất:")) return "Mục đích sử dụng đất: Không có dữ liệu trong tin đăng.";
        if (s.startsWith("5. Công năng sử dụng:")) return "5. Công năng sử dụng: " + text(d.getUseRules());
        if (s.startsWith("6. Trang thiết bị kèm theo:")) return "6. Trang thiết bị kèm theo: " + text(d.getEquipment());
        if (s.startsWith("1. Giá thuê nhà ở là")) return "1. Giá thuê nhà ở là " + money(c.getMonthlyRent()) + " đồng/tháng (Bằng chữ: " + amountWords(c.getMonthlyRent()) + "). Tiền đặt cọc: " + money(c.getDepositAmount()) + " đồng. " + text(d.getDepositTerms());
        if (s.startsWith("(Việt Nam đồng/tháng")) return "(Giá thuê tính theo tháng. Bằng chữ: " + amountWords(c.getMonthlyRent()) + ").";
        if (s.startsWith("Giá thuê này đã bao gồm:")) return "Giá thuê này đã bao gồm: " + text(d.getServiceFees());
        if (s.startsWith("3. Các thỏa thuận khác (nếu có)")) return "3. Các thỏa thuận khác: " + note(c);
        if (s.startsWith("2. Các thỏa thuận khác") || s.startsWith("4. Các thỏa thuận khác") || s.startsWith("5. Các thỏa thuận khác")) return s.substring(0, s.indexOf(':') + 1) + " " + note(c);
        if (s.startsWith("1. Phương thức thanh toán:")) return "1. Phương thức thanh toán: " + text(d.getPaymentMethod());
        if (s.startsWith("2. Thời hạn thực hiện thanh toán:")) return "2. Thời hạn thực hiện thanh toán: Ngày " + d.getPaymentDay() + " hằng tháng.";
        if (s.startsWith("2. Các chi phí sử dụng điện, nước")) return "2. Chi phí điện: " + text(d.getElectricityTerms()) + ". Chi phí nước: " + text(d.getWaterTerms()) + ".";
        if (s.startsWith("1. Thời hạn cho thuê nhà ở:")) return "1. Thời hạn cho thuê nhà ở: từ ngày " + date(c.getStartDate()) + " đến ngày " + date(c.getEndDate()) + ".";
        if (s.startsWith("2. Thời điểm giao nhận nhà ở:")) return "2. Thời điểm giao nhận nhà ở: ngày " + date(parseDate(d.getHandoverDate(), c.getStartDate())) + ".";
        if (s.startsWith("3. Hồ sơ kèm theo:")) return "3. Hồ sơ kèm theo: thông tin tin đăng và các thỏa thuận được ghi nhận trong hợp đồng.";
        if (s.startsWith("1. Mục đích sử dụng nhà ở của bên thuê:")) return "1. Mục đích sử dụng nhà ở của bên thuê: " + text(d.getUseRules());
        if (s.startsWith("2. Các hạn chế sử dụng nhà ở:")) return "2. Các hạn chế sử dụng nhà ở: " + text(d.getUseRules());
        if (s.startsWith("3. Đóng phí dịch vụ, phí quản lý vận hành:")) return "3. Đóng phí dịch vụ, phí quản lý vận hành: " + text(d.getServiceFees());
        if (s.startsWith("4. Ban hành và tuân thủ nội quy")) return "4. Ban hành và tuân thủ nội quy, quy chế quản lý vận hành khu nhà ở: " + text(d.getUseRules());
        if (s.startsWith("1. Trách nhiệm của bên cho thuê khi vi phạm hợp đồng")) return "1. Trách nhiệm của bên cho thuê khi vi phạm hợp đồng: " + text(d.getViolationTerms());
        if (s.startsWith("2. Trách nhiệm của bên thuê khi vi phạm hợp đồng")) return "2. Trách nhiệm của bên thuê khi vi phạm hợp đồng: " + text(d.getViolationTerms());
        if (s.startsWith("Do các bên thỏa thuận:")) return "Do các bên thỏa thuận: " + text(d.getViolationTerms());
        if (s.startsWith("2. Việc xử lý hậu quả do chấm dứt hợp đồng")) return "2. Việc xử lý hậu quả do chấm dứt hợp đồng: " + text(d.getDepositTerms());
        if (s.startsWith("Các bên có trách nhiệm thỏa thuận cụ thể cách thức")) return "Các bên giải quyết tranh chấp bằng thương lượng; nếu không thống nhất thì yêu cầu Tòa án có thẩm quyền giải quyết theo pháp luật.";
        if (s.startsWith("1. Hợp đồng này có hiệu lực kể từ ngày")) return "1. Hợp đồng này có hiệu lực kể từ ngày " + date(c.getStartDate()) + ".";
        if (s.startsWith("2. Hợp đồng này có .... điều")) return "2. Hợp đồng này có 12 điều, được lập thành 02 bản, mỗi bên giữ 01 bản có giá trị như nhau.";
        if (s.startsWith("3. Kèm theo hợp đồng này các giấy tờ về nhà ở")) return "3. Kèm theo hợp đồng này: thông tin tin đăng và các thỏa thuận được ghi nhận trong hợp đồng.";
        return null;
    }

    private List<XWPFParagraph> paragraphs(XWPFDocument doc) {
        List<XWPFParagraph> result = new ArrayList<>(doc.getParagraphs());
        for (XWPFTable table : doc.getTables()) addTableParagraphs(table, result);
        return result;
    }
    private void addTableParagraphs(XWPFTable table, List<XWPFParagraph> result) {
        for (XWPFTableRow row : table.getRows()) for (XWPFTableCell cell : row.getTableCells()) {
            result.addAll(cell.getParagraphs());
            for (XWPFTable nested : cell.getTables()) addTableParagraphs(nested, result);
        }
    }
    private void setText(XWPFParagraph paragraph, String value) {
        List<XWPFRun> runs = paragraph.getRuns();
        if (runs.isEmpty()) paragraph.createRun().setText(value);
        else {
            runs.get(0).setText(value, 0);
            for (int i = 1; i < runs.size(); i++) runs.get(i).setText("", 0);
        }
    }
    private String extractText(XWPFDocument doc) {
        StringBuilder out = new StringBuilder();
        for (XWPFParagraph p : paragraphs(doc)) if (p.getText() != null && !p.getText().isBlank()) out.append(p.getText()).append("\n\n");
        return out.toString().trim();
    }
    private String text(String s) { return s == null || s.isBlank() ? "Chưa cung cấp" : s.trim(); }
    private String note(Contract c) { return c.getNote() == null || c.getNote().isBlank() ? "Không có." : c.getNote().trim(); }
    private String date(LocalDate d) { return d.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")); }
    private String longDate(LocalDate d) { return "ngày " + d.getDayOfMonth() + " tháng " + d.getMonthValue() + " năm " + d.getYear(); }
    private LocalDate parseDate(String s, LocalDate fallback) { try { return LocalDate.parse(s); } catch (Exception ignored) { return fallback; } }
    private String money(BigDecimal value) { return NumberFormat.getNumberInstance(Locale.forLanguageTag("vi-VN")).format(value); }
    private String area(Contract c, ContractDetails d) { return d.getListingAreaSqmSnapshot() == null ? c.getListing().getAreaSqm().stripTrailingZeros().toPlainString() : d.getListingAreaSqmSnapshot(); }

    private String amountWords(BigDecimal amount) {
        long value = amount.longValue();
        if (value == 0) return "không đồng";
        String[] units = {"", " nghìn", " triệu", " tỷ", " nghìn tỷ", " triệu tỷ"};
        String[] digit = {"không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"};
        List<String> groups = new ArrayList<>();
        int unit = 0;
        while (value > 0) {
            int group = (int)(value % 1000);
            if (group > 0) groups.add(0, groupWords(group, digit) + units[unit]);
            value /= 1000;
            unit++;
        }
        return String.join(" ", groups).replaceAll("\\s+", " ").trim() + " đồng";
    }
    private String groupWords(int n, String[] d) {
        int h=n/100, t=(n%100)/10, u=n%10;
        StringBuilder s=new StringBuilder();
        if(h>0 || n>=100) s.append(d[h]).append(" trăm");
        if(t>1) s.append(" ").append(d[t]).append(" mươi");
        else if(t==1) s.append(" mười");
        else if(h>0 && u>0) s.append(" lẻ");
        if(u>0) {
            if(t>1 && u==1) s.append(" mốt");
            else if(t>0 && u==5) s.append(" lăm");
            else s.append(" ").append(d[u]);
        }
        return s.toString().trim();
    }
}
