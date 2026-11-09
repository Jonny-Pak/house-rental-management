package com.rental.modules.contract.service;

import com.rental.core.excel.ExcelImportResult;
import com.rental.modules.contract.dto.request.*;
import com.rental.modules.contract.dto.response.ContractResponse;
import com.rental.modules.contract.repository.ContractRepository;
import com.rental.modules.listing.service.ListingService;
import jakarta.validation.Validator;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.*;
import static com.rental.core.excel.ExcelWorkbook.*;

@Service
public class ContractExcelService {
    public static final List<String> HEADERS = List.of("Mã tin", "Điện thoại người thuê", "Ngày bắt đầu", "Ngày kết thúc", "Tiền thuê tháng", "Tiền cọc", "Ghi chú",
        "Giấy tờ chủ nhà", "Địa chỉ chủ nhà", "Giấy tờ người thuê", "Địa chỉ người thuê", "Nơi lập hợp đồng", "Ngày lập", "Ngày bàn giao",
        "Thanh toán", "Chi phí điện", "Chi phí nước", "Ngày trả tiền", "Phí dịch vụ", "Hiện trạng", "Thiết bị", "Nội quy", "Điều khoản cọc", "Chấm dứt", "Vi phạm");
    private final ContractService contracts;
    private final ContractRepository repository;
    private final ListingService listings;
    private final ContractExcelWriter writer;
    private final Validator validator;

    public ContractExcelService(ContractService contracts, ContractRepository repository, ListingService listings, ContractExcelWriter writer, Validator validator) {
        this.contracts = contracts; this.repository = repository; this.listings = listings; this.writer = writer; this.validator = validator;
    }

    public byte[] template(Long ownerId) { return workbook(List.of(), ownerId); }
    public byte[] exportContracts(String email) { return workbook(contracts.getMyContracts(email), null); }
    public ExcelImportResult preview(String email, Long ownerId, MultipartFile file) { return read(email, ownerId, file).result(0); }

    public ExcelImportResult importContracts(String email, Long ownerId, MultipartFile file) {
        Parsed parsed = read(email, ownerId, file);
        if (!parsed.errors.isEmpty()) return parsed.result(0);
        writer.importAll(email, parsed.requests);
        return parsed.result(parsed.requests.size());
    }

    private byte[] workbook(List<ContractResponse> rows, Long ownerId) {
        try (var book = new XSSFWorkbook(); var output = new ByteArrayOutputStream()) {
            Sheet sheet = book.createSheet("HopDong");
            var headers = new ArrayList<>(HEADERS);
            headers.addAll(List.of("Mã hợp đồng (chỉ xem)", "Trạng thái (chỉ xem)", "Tên tin (chỉ xem)", "Chủ nhà (chỉ xem)", "Người thuê (chỉ xem)"));
            writeRow(sheet.createRow(0), headers);
            CellStyle textStyle = book.createCellStyle();
            textStyle.setDataFormat(book.createDataFormat().getFormat("@"));
            for (int column : List.of(1, 7, 9)) sheet.setDefaultColumnStyle(column, textStyle);
            for (var row : rows) writeRow(sheet.createRow(sheet.getLastRowNum() + 1), values(row));
            style(book, sheet, headers.size());
            if (ownerId != null) {
                Sheet owned = book.createSheet("TinCuaToi");
                writeRow(owned.createRow(0), List.of("Mã tin", "Tiêu đề", "Địa chỉ", "Kiểm duyệt", "Cho thuê"));
                for (var l : listings.getMyListings(ownerId)) writeRow(owned.createRow(owned.getLastRowNum() + 1), Arrays.asList(l.getId(), l.getTitle(), l.getAddress(), l.getApprovalStatus(), l.getRentalStatus()));
                style(book, owned, 5);
            }
            Sheet help = book.createSheet("HuongDan");
            List<String> notes = List.of(
                "Nhập dữ liệu vào sheet HopDong, không sửa hàng tiêu đề. Tối đa 500 dòng, 5 MB, chỉ nhận .xlsx.",
                "Mỗi dòng tạo hợp đồng DRAFT chờ người thuê xác nhận, không tự có hiệu lực. Không dùng để cập nhật hoặc ký hợp đồng cũ.",
                "Mã tin phải thuộc chủ nhà đang đăng nhập, đã duyệt, còn trống và chưa có hợp đồng DRAFT/ACTIVE. Tra sheet TinCuaToi trong file mẫu.",
                "Người thuê phải có tài khoản hợp lệ trong hệ thống. Định dạng cột Điện thoại và Giấy tờ là Text để giữ số 0 đầu.",
                "Ngày nhập dạng yyyy-MM-dd (ví dụ 2027-01-01), hoặc ô ngày Excel. Ngày kết thúc phải sau ngày bắt đầu và ngày hiện tại.",
                "Các cột từ Mã tin đến Chi phí nước đều bắt buộc, trừ Ghi chú. Tiền thuê > 0, tiền cọc >= 0, đơn vị VND, không kèm dấu phân cách hàng nghìn.",
                "Ngày trả tiền từ 1–28, mặc định 5. Ngày bàn giao nằm trong kỳ thuê. Ngày lập không sau ngày kết thúc.",
                "Các cột từ Phí dịch vụ đến Vi phạm có thể để trống để dùng điều khoản mặc định theo mẫu hợp đồng của ứng dụng.",
                "Có dòng lỗi thì chưa nhập bất kỳ hợp đồng nào. Cần kiểm tra dữ liệu và nội dung hợp đồng trước khi xác nhận nhập.",
                "Mã hợp đồng, Trạng thái, Tên tin, Chủ nhà, Người thuê là cột chỉ xem. Không nhập công thức Excel.");
            for (int i = 0; i < notes.size(); i++) help.createRow(i).createCell(0).setCellValue(notes.get(i));
            help.setColumnWidth(0, 120 * 256);
            book.write(output);
            return output.toByteArray();
        } catch (java.io.IOException e) { throw bad("Không tạo được file hợp đồng Excel."); }
    }

    private List<Object> values(ContractResponse c) {
        ContractDetails d = c.details() == null ? new ContractDetails() : c.details();
        return Arrays.asList(c.listingId(), d.getTenantPhone(), String.valueOf(c.startDate()), String.valueOf(c.endDate()), c.monthlyRent(), c.depositAmount(), c.note(),
            d.getLandlordIdentity(), d.getLandlordAddress(), d.getTenantIdentity(), d.getTenantAddress(), d.getSigningPlace(), d.getSigningDate(), d.getHandoverDate(),
            d.getPaymentMethod(), d.getElectricityTerms(), d.getWaterTerms(), d.getPaymentDay(), d.getServiceFees(), d.getConditionDescription(), d.getEquipment(),
            d.getUseRules(), d.getDepositTerms(), d.getTerminationTerms(), d.getViolationTerms(), c.id(), c.status(), c.listingName(), c.landlordName(), c.tenantName());
    }

    private Parsed read(String email, Long ownerId, MultipartFile file) {
        checkFile(file);
        Parsed parsed = new Parsed();
        var owned = listings.getMyListings(ownerId);
        Set<Long> seen = new HashSet<>();
        try (var input = file.getInputStream(); var book = new XSSFWorkbook(input)) {
            Sheet sheet = checkSheet(book, "HopDong", HEADERS);
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (empty(row, HEADERS.size())) continue;
                parsed.total++;
                try {
                    var request = request(email, row);
                    var listing = owned.stream().filter(l -> l.getId().equals(request.getListingId())).findFirst().orElse(null);
                    if (listing == null) throw new IllegalArgumentException("Mã tin không thuộc tài khoản của bạn.");
                    if (!"APPROVED".equals(listing.getApprovalStatus()) || !"AVAILABLE".equals(listing.getRentalStatus())) throw new IllegalArgumentException("Tin phải đã duyệt và còn trống.");
                    if (!seen.add(request.getListingId()) || repository.existsByListing_IdAndStatusInAndIdNot(request.getListingId(), List.of("DRAFT", "ACTIVE"), -1L)) throw new IllegalArgumentException("Tin đã có hợp đồng chờ xác nhận/hiệu lực hoặc trùng trong file.");
                    if (!validator.validate(request).isEmpty()) throw new IllegalArgumentException("Thông tin hợp đồng thiếu, quá dài hoặc giá trị số không hợp lệ.");
                    contracts.previewContract(email, request);
                    parsed.requests.add(request);
                    parsed.rows.add(new ExcelImportResult.RowPreview(i + 1, listing.getTitle(), "Người thuê: " + text(row, 1) + " · " + request.getStartDate() + " → " + request.getEndDate()));
                } catch (ResponseStatusException ex) {
                    parsed.errors.add(new ExcelImportResult.RowError(i + 1, ex.getReason()));
                } catch (IllegalArgumentException ex) {
                    parsed.errors.add(new ExcelImportResult.RowError(i + 1, ex.getMessage()));
                }
            }
            if (parsed.total == 0) throw bad("File chưa có hợp đồng nào để nhập.");
            return parsed;
        } catch (ResponseStatusException ex) { throw ex; }
        catch (Exception ex) { throw bad("Không đọc được Excel. Hãy dùng file mẫu .xlsx, không đặt mật khẩu và không dùng công thức."); }
    }

    private CreateContractRequest request(String email, Row row) {
        var r = new CreateContractRequest();
        r.setListingId(id(row, 0));
        if (r.getListingId() == null) throw new IllegalArgumentException("Cần nhập Mã tin.");
        String phone = text(row, 1);
        var tenant = contracts.findTenant(email, null, phone, r.getListingId());
        r.setTenantId(((Number) tenant.get("id")).longValue());
        r.setStartDate(date(row, 2)); r.setEndDate(date(row, 3)); r.setMonthlyRent(number(row, 4)); r.setDepositAmount(number(row, 5)); r.setNote(text(row, 6));
        var d = new ContractDetails();
        d.setLandlordIdentity(text(row, 7)); d.setLandlordAddress(text(row, 8)); d.setTenantIdentity(text(row, 9)); d.setTenantAddress(text(row, 10));
        d.setSigningPlace(text(row, 11));
        LocalDate signing = date(row, 12), handover = date(row, 13);
        d.setSigningDate(signing == null ? null : signing.toString()); d.setHandoverDate(handover == null ? null : handover.toString());
        d.setPaymentMethod(text(row, 14)); d.setElectricityTerms(text(row, 15)); d.setWaterTerms(text(row, 16));
        Long day = id(row, 17);
        if (day != null) {
            if (day < 1 || day > 28) throw new IllegalArgumentException("Ngày trả tiền phải từ 1 đến 28.");
            d.setPaymentDay(day.intValue());
        }
        if (text(row, 18) != null) d.setServiceFees(text(row, 18));
        if (text(row, 19) != null) d.setConditionDescription(text(row, 19));
        if (text(row, 20) != null) d.setEquipment(text(row, 20));
        if (text(row, 21) != null) d.setUseRules(text(row, 21));
        if (text(row, 22) != null) d.setDepositTerms(text(row, 22));
        if (text(row, 23) != null) d.setTerminationTerms(text(row, 23));
        if (text(row, 24) != null) d.setViolationTerms(text(row, 24));
        r.setDetails(d);
        return r;
    }

    private static class Parsed {
        int total;
        final List<CreateContractRequest> requests = new ArrayList<>();
        final List<ExcelImportResult.RowPreview> rows = new ArrayList<>();
        final List<ExcelImportResult.RowError> errors = new ArrayList<>();
        ExcelImportResult result(int imported) { return new ExcelImportResult(total, imported, rows, errors); }
    }
}
