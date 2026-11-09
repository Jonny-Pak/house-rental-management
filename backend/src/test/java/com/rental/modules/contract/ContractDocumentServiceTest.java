package com.rental.modules.contract;

import com.rental.modules.contract.domain.entity.Contract;
import com.rental.modules.contract.dto.request.ContractDetails;
import com.rental.modules.contract.service.ContractDocumentService;
import com.rental.modules.listing.domain.entity.Listing;
import com.rental.modules.user.domain.entity.User;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import static org.junit.jupiter.api.Assertions.*;

class ContractDocumentServiceTest {
    private final ContractDocumentService documents = new ContractDocumentService();

    private Contract contract(String type) {
        User owner = new User(); owner.setFullName("Nguyễn Văn Chủ"); owner.setPhoneNumber("0901000001");
        User tenant = new User(); tenant.setFullName("Trần Văn Thuê"); tenant.setPhoneNumber("0901000002");
        Listing listing = new Listing(); listing.setTitle("Nhà/phòng mẫu"); listing.setAddress("TP.HCM");
        listing.setAreaSqm(new BigDecimal("45")); listing.setListingType(type);
        Contract contract = new Contract(listing, owner, tenant, LocalDate.of(2027,1,1), LocalDate.of(2028,1,1),
                new BigDecimal("5000000"), new BigDecimal("5000000"), "DRAFT", null, LocalDateTime.now());
        contract.setId(7L);
        return contract;
    }

    private ContractDetails details() {
        ContractDetails details = new ContractDetails();
        details.setLandlordIdentity("CCCD chủ nhà; ngày cấp; nơi cấp"); details.setLandlordAddress("Địa chỉ chủ nhà");
        details.setTenantIdentity("CCCD người thuê; ngày cấp; nơi cấp"); details.setTenantAddress("Địa chỉ người thuê");
        details.setSigningDate("2026-12-25"); details.setSigningPlace("TP.HCM"); details.setHandoverDate("2027-01-01");
        details.setPaymentMethod("Chuyển khoản theo tài khoản thỏa thuận");
        details.setElectricityTerms("Theo hóa đơn điện"); details.setWaterTerms("Theo hóa đơn nước");
        return details;
    }

    @Test void generatesHouseTemplateWithPartiesMoneyDatesAndTwelveArticles() {
        Contract contract = contract("WHOLE_HOUSE");
        documents.prepare(contract, details());
        assertEquals("HOUSE", contract.getContractType());
        String text = contract.getDocumentText();
        assertTrue(text.contains("HỢP ĐỒNG THUÊ NHÀ Ở"));
        assertTrue(text.contains("Điều 12."));
        assertTrue(text.contains("Nguyễn Văn Chủ"));
        assertTrue(text.contains("Trần Văn Thuê"));
        assertTrue(text.contains("5.000.000"));
        assertTrue(text.contains("01/01/2027"));
        assertFalse(text.contains("{{"));
        assertFalse(text.contains("Bên mua"));
    }

    @Test void roomTemplateHasUtilityRulesAndSavedSnapshotDoesNotFollowProfileChanges() {
        Contract contract = contract("BOARDING_ROOM");
        ContractDetails details = details(); details.setTenantName("Tên giả từ request");
        documents.prepare(contract, details);
        assertEquals("ROOM", contract.getContractType());
        String text = contract.getDocumentText();
        assertTrue(text.contains("HỢP ĐỒNG THUÊ PHÒNG TRỌ"));
        assertTrue(text.contains("Theo hóa đơn điện"));
        assertFalse(text.contains("Tên giả từ request"));
        contract.getTenant().setFullName("Tên tài khoản mới");
        contract.getListing().setAddress("Địa chỉ tin đã đổi");
        assertEquals(text, contract.getDocumentText());
        assertEquals("Trần Văn Thuê", documents.readDetails(contract).getTenantName());
    }

    @Test void rejectsMissingIdentityInvalidDatesAndPaymentDays() {
        Contract contract = contract("WHOLE_HOUSE");
        assertThrows(ResponseStatusException.class, () -> documents.prepare(contract, null));
        ContractDetails details = details(); details.setTenantIdentity(" ");
        assertThrows(ResponseStatusException.class, () -> documents.prepare(contract, details));
        details.setTenantIdentity("CCCD mẫu"); details.setSigningDate("2026-02-31");
        assertThrows(ResponseStatusException.class, () -> documents.prepare(contract, details));
        details.setSigningDate("2026-12-25"); details.setHandoverDate("2026-01-01");
        assertThrows(ResponseStatusException.class, () -> documents.prepare(contract, details));
        details.setHandoverDate("2027-01-01"); details.setPaymentDay(31);
        assertThrows(ResponseStatusException.class, () -> documents.prepare(contract, details));
    }

    @Test void userTextIsNotExpandedAsAnotherTemplateVariable() {
        Contract contract = contract("WHOLE_HOUSE");
        contract.setNote("Giữ nguyên chuỗi {{landlordIdentity}} theo nội dung nhập.");
        documents.prepare(contract, details());
        assertTrue(contract.getDocumentText().contains("Giữ nguyên chuỗi {{landlordIdentity}}"));
    }
}
