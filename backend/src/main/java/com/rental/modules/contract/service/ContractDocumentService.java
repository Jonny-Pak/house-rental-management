package com.rental.modules.contract.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rental.modules.contract.domain.entity.Contract;
import com.rental.modules.contract.dto.request.ContractDetails;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

@Service
public class ContractDocumentService {
    private final ObjectMapper mapper = new ObjectMapper();

    public void prepare(Contract contract, ContractDetails details) {
        validate(details, contract.getStartDate(), contract.getEndDate());
        details.setLandlordName(contract.getLandlord().getFullName());
        details.setLandlordPhone(contract.getLandlord().getPhoneNumber());
        details.setTenantName(contract.getTenant().getFullName());
        details.setTenantPhone(contract.getTenant().getPhoneNumber());
        String listingType = contract.getListing().getListingType();
        boolean room = "BOARDING_ROOM".equals(listingType) || "SHARED_ROOM".equals(listingType);
        contract.setContractType(room ? "ROOM" : "HOUSE");
        try {
            contract.setDetailsJson(mapper.writeValueAsString(details));
        } catch (JsonProcessingException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không lưu được thông tin hợp đồng.");
        }
        contract.setDocumentText(build(contract, details));
    }

    public ContractDetails readDetails(Contract contract) {
        if (contract.getDetailsJson() == null) return null;
        try {
            return mapper.readValue(contract.getDetailsJson(), ContractDetails.class);
        } catch (JsonProcessingException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Không đọc được thông tin hợp đồng.");
        }
    }

    public void validate(ContractDetails details, LocalDate start, LocalDate end) {
        if (details == null) throw badRequest("Cần bổ sung thông tin hợp đồng theo mẫu.");
        require(details.getLandlordIdentity(), "Giấy tờ tùy thân chủ nhà");
        require(details.getLandlordAddress(), "Địa chỉ chủ nhà");
        require(details.getTenantIdentity(), "Giấy tờ tùy thân người thuê");
        require(details.getTenantAddress(), "Địa chỉ người thuê");
        require(details.getSigningPlace(), "Địa điểm lập hợp đồng");
        require(details.getPaymentMethod(), "Phương thức thanh toán");
        require(details.getElectricityTerms(), "Chi phí điện");
        require(details.getWaterTerms(), "Chi phí nước");
        require(details.getServiceFees(), "Phí dịch vụ");
        require(details.getConditionDescription(), "Hiện trạng nhà/phòng");
        require(details.getEquipment(), "Trang thiết bị");
        require(details.getUseRules(), "Nội quy sử dụng");
        require(details.getDepositTerms(), "Thỏa thuận tiền cọc");
        require(details.getTerminationTerms(), "Thỏa thuận chấm dứt");
        require(details.getViolationTerms(), "Xử lý vi phạm");
        LocalDate signing = parseDate(details.getSigningDate());
        LocalDate handover = parseDate(details.getHandoverDate());
        if (signing.isAfter(end)) throw badRequest("Ngày lập hợp đồng không được sau ngày kết thúc.");
        if (handover.isBefore(start) || handover.isAfter(end)) throw badRequest("Ngày bàn giao phải nằm trong thời hạn thuê.");
        if (details.getPaymentDay() < 1 || details.getPaymentDay() > 28) throw badRequest("Ngày thanh toán phải từ 1 đến 28.");
    }

    private void require(String value, String label) {
        if (value == null || value.isBlank()) throw badRequest("Cần nhập: " + label + ".");
    }

    private LocalDate parseDate(String value) {
        try {
            return LocalDate.parse(value == null ? "" : value);
        } catch (DateTimeParseException exception) {
            throw badRequest("Ngày lập và ngày bàn giao phải đúng định dạng yyyy-MM-dd.");
        }
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }

    private String build(Contract contract, ContractDetails details) {
        Map<String, String> values = new HashMap<>();
        values.put("landlordIdentity", text(details.getLandlordIdentity()));
        values.put("landlordAddress", text(details.getLandlordAddress()));
        values.put("tenantIdentity", text(details.getTenantIdentity()));
        values.put("tenantAddress", text(details.getTenantAddress()));
        values.put("signingPlace", text(details.getSigningPlace()));
        values.put("paymentMethod", text(details.getPaymentMethod()));
        values.put("electricityTerms", text(details.getElectricityTerms()));
        values.put("waterTerms", text(details.getWaterTerms()));
        values.put("serviceFees", text(details.getServiceFees()));
        values.put("conditionDescription", text(details.getConditionDescription()));
        values.put("equipment", text(details.getEquipment()));
        values.put("useRules", text(details.getUseRules()));
        values.put("depositTerms", text(details.getDepositTerms()));
        values.put("terminationTerms", text(details.getTerminationTerms()));
        values.put("violationTerms", text(details.getViolationTerms()));
        values.put("landlordName", text(details.getLandlordName()));
        values.put("landlordPhone", text(details.getLandlordPhone()));
        values.put("tenantName", text(details.getTenantName()));
        values.put("tenantPhone", text(details.getTenantPhone()));
        values.put("signingDate", date(details.getSigningDate()));
        values.put("handoverDate", date(details.getHandoverDate()));
        values.put("paymentDay", String.valueOf(details.getPaymentDay()));
        values.put("title", "ROOM".equals(contract.getContractType()) ? "HỢP ĐỒNG THUÊ PHÒNG TRỌ" : "HỢP ĐỒNG THUÊ NHÀ Ở");
        values.put("contractNumber", contract.getId() == null ? "DỰ THẢO" : "HĐ-" + contract.getId());
        values.put("listingTitle", text(contract.getListingTitle()));
        values.put("address", text(contract.getListingAddress()));
        values.put("area", contract.getListing().getAreaSqm().stripTrailingZeros().toPlainString());
        values.put("startDate", date(contract.getStartDate().toString()));
        values.put("endDate", date(contract.getEndDate().toString()));
        values.put("monthlyRent", money(contract.getMonthlyRent()));
        values.put("depositAmount", money(contract.getDepositAmount()));
        values.put("note", contract.getNote() == null || contract.getNote().isBlank() ? "Không có." : contract.getNote());
        String resource = "ROOM".equals(contract.getContractType()) ? "contracts/room.txt" : "contracts/house.txt";
        try (var input = new ClassPathResource(resource).getInputStream()) {
            return fill(new String(input.readAllBytes(), StandardCharsets.UTF_8), values);
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Không đọc được mẫu hợp đồng.");
        }
    }

    private String text(String value) {
        return value == null || value.isBlank() ? "Chưa cung cấp" : value.trim();
    }

    private String date(String value) {
        return LocalDate.parse(value).format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    }

    private String money(BigDecimal value) {
        return NumberFormat.getNumberInstance(Locale.forLanguageTag("vi-VN")).format(value);
    }

    private String fill(String template, Map<String, String> values) {
        StringBuilder result = new StringBuilder();
        int position = 0;
        while (position < template.length()) {
            int start = template.indexOf("{{", position);
            if (start < 0) {
                result.append(template.substring(position));
                break;
            }
            int end = template.indexOf("}}", start);
            if (end < 0) throw new IllegalStateException("Mẫu hợp đồng có biến chưa đóng.");
            result.append(template, position, start);
            String key = template.substring(start + 2, end);
            if (!values.containsKey(key)) throw new IllegalStateException("Mẫu hợp đồng có biến không hỗ trợ: " + key);
            result.append(values.get(key));
            position = end + 2;
        }
        return result.toString();
    }
}
