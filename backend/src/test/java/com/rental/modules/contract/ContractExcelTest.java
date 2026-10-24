package com.rental.modules.contract;

import com.rental.modules.contract.service.*;
import com.rental.modules.contract.repository.ContractRepository;
import com.rental.modules.listing.service.ListingService;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.listing.ListingExcelTest;
import jakarta.validation.Validation;
import org.junit.jupiter.api.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

class ContractExcelTest {
    ContractService contracts;
    ContractExcelWriter writer;
    ContractRepository repository;
    ContractExcelService excel;
    ListingResponse listing;
    jakarta.validation.ValidatorFactory factory;

    @BeforeEach void setup() {
        contracts = mock(ContractService.class); writer = mock(ContractExcelWriter.class); repository = mock(ContractRepository.class);
        var listings = mock(ListingService.class);
        listing = new ListingResponse(); listing.setId(5L); listing.setTitle("Nhà kiểm thử"); listing.setApprovalStatus("APPROVED"); listing.setRentalStatus("AVAILABLE");
        when(listings.getMyListings(1L)).thenReturn(List.of(listing));
        when(contracts.findTenant("owner", null, "0901234567", 5L)).thenReturn(Map.of("id", 2L));
        factory = Validation.buildDefaultValidatorFactory();
        excel = new ContractExcelService(contracts, repository, listings, writer, factory.getValidator());
    }
    @AfterEach void close() { factory.close(); }

    public static List<Object> contractRow(Long listingId, String phone) {
        return new ArrayList<>(Arrays.asList(listingId, phone, "2027-01-01", "2028-01-01", 3000000, 1000000, "Ghi chú",
            "001234567890", "Địa chỉ chủ nhà", "009876543210", "Địa chỉ người thuê", "TP.HCM", "2027-01-01", "2027-01-01", "Chuyển khoản", "Theo hóa đơn", "Theo hóa đơn"));
    }

    @Test void previewDoesNotWriteAndImportCreatesValidatedRequests() throws Exception {
        var file = ListingExcelTest.file("HopDong", ContractExcelService.HEADERS, List.of(contractRow(5L, "0901234567")));
        assertTrue(excel.preview("owner", 1L, file).errors().isEmpty());
        verifyNoInteractions(writer);
        assertEquals(1, excel.importContracts("owner", 1L, file).importedRows());
        verify(writer).importAll(eq("owner"), argThat(rows -> rows.size() == 1 && rows.get(0).getTenantId() == 2L && rows.get(0).getDetails().getPaymentDay() == 5));
    }

    @Test void missingDetailsAndBadDatesPreventTheWholeImport() throws Exception {
        var row = contractRow(5L, "0901234567"); row.set(2, "not-date");
        var result = excel.importContracts("owner", 1L, ListingExcelTest.file("HopDong", ContractExcelService.HEADERS, List.of(row)));
        assertEquals(0, result.importedRows()); assertEquals(2, result.errors().get(0).row());
        verifyNoInteractions(writer);
    }

    @Test void existingDraftAndWrongOwnerCannotBeImported() throws Exception {
        when(repository.existsByListing_IdAndStatusInAndIdNot(5L, List.of("DRAFT", "ACTIVE"), -1L)).thenReturn(true);
        var file = ListingExcelTest.file("HopDong", ContractExcelService.HEADERS, List.of(contractRow(5L, "0901234567")));
        assertFalse(excel.importContracts("owner", 1L, file).errors().isEmpty());
        assertFalse(excel.importContracts("owner", 99L, file).errors().isEmpty());
        verifyNoInteractions(writer);
    }

    @Test void unavailableListingAndDuplicatesPreventImport() throws Exception {
        listing.setRentalStatus("RENTED");
        var row = contractRow(5L, "0901234567");
        assertFalse(excel.preview("owner", 1L, ListingExcelTest.file("HopDong", ContractExcelService.HEADERS, List.of(row))).errors().isEmpty());
        listing.setRentalStatus("AVAILABLE");
        var duplicate = excel.importContracts("owner", 1L, ListingExcelTest.file("HopDong", ContractExcelService.HEADERS, List.of(row, row)));
        assertEquals(3, duplicate.errors().get(0).row()); verifyNoInteractions(writer);
    }

    @Test void templateContainsOwnedListingReferenceAndPhoneTextFormat() throws Exception {
        try (var book = new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(excel.template(1L)))) {
            assertNotNull(book.getSheet("TinCuaToi")); assertNotNull(book.getSheet("HuongDan"));
            assertEquals("@", book.getSheet("HopDong").getColumnStyle(1).getDataFormatString());
        }
    }
}
