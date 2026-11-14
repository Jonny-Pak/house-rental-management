package com.rental.modules.contract.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rental.modules.contract.domain.entity.Contract;
import com.rental.modules.contract.dto.request.ContractDetails;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

@Service
public class ContractDocumentService {
    private final ObjectMapper mapper = new ObjectMapper();
    private final ContractWordService word;

    public ContractDocumentService() { this.word = new ContractWordService(); }
    @Autowired
    public ContractDocumentService(ContractWordService word) { this.word = word; }

    public void prepare(Contract contract, ContractDetails details) {
        validate(details, contract.getStartDate(), contract.getEndDate());
        details.setLandlordName(contract.getLandlord().getFullName());
        details.setLandlordPhone(contract.getLandlord().getPhoneNumber());
        details.setTenantName(contract.getTenant().getFullName());
        details.setTenantPhone(contract.getTenant().getPhoneNumber());
        details.setListingAreaSqmSnapshot(contract.getListing().getAreaSqm().stripTrailingZeros().toPlainString());
        String listingType = contract.getListing().getListingType();
        boolean room = "BOARDING_ROOM".equals(listingType) || "SHARED_ROOM".equals(listingType);
        contract.setContractType(room ? "ROOM" : "HOUSE");
        try {
            contract.setDetailsJson(mapper.writeValueAsString(details));
        } catch (JsonProcessingException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không lưu được thông tin hợp đồng.");
        }
        contract.setDocumentText(word.generate(contract, details).text());
    }

    public byte[] generateWord(Contract contract) {
        ContractDetails details = readDetails(contract);
        if (details == null) throw new ResponseStatusException(HttpStatus.CONFLICT, "Hợp đồng chưa có nội dung theo mẫu.");
        return word.generate(contract, details).bytes();
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

}
