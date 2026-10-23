package com.rental.modules.listing;

import com.rental.core.excel.ExcelWorkbook;
import com.rental.modules.listing.service.*;
import com.rental.modules.listing.dto.response.ListingResponse;
import com.rental.modules.area.domain.entity.AdministrativeArea;
import com.rental.modules.area.repository.AdministrativeAreaRepository;
import jakarta.validation.Validation;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.MockMultipartFile;
import java.io.ByteArrayOutputStream;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

public class ListingExcelTest {
    ListingService listings;
    ListingExcelService excel;
    jakarta.validation.ValidatorFactory factory;

    @BeforeEach void setup() {
        listings = mock(ListingService.class);
        var areas = mock(AdministrativeAreaRepository.class);
        var ward = new AdministrativeArea(); ward.setAreaId(6L); ward.setAreaName("Phường kiểm thử"); ward.setAreaType("WARD");
        when(areas.findAll()).thenReturn(List.of(ward));
        factory = Validation.buildDefaultValidatorFactory();
        excel = new ListingExcelService(listings, areas, factory.getValidator());
    }
    @AfterEach void close() { factory.close(); }

    public static List<Object> listingRow(String title) {
        return new ArrayList<>(Arrays.asList(title, "BOARDING_ROOM", 2500000, 25.5, "Địa chỉ tiếng Việt", 6, 10.78, 106.7, "https://example.com/room.jpg", "Mô tả"));
    }

    public static MockMultipartFile file(String sheetName, List<String> headers, List<List<Object>> rows) throws Exception {
        try (var book = new XSSFWorkbook(); var bytes = new ByteArrayOutputStream()) {
            var sheet = book.createSheet(sheetName);
            ExcelWorkbook.writeRow(sheet.createRow(0), headers);
            for (int i = 0; i < rows.size(); i++) ExcelWorkbook.writeRow(sheet.createRow(i + 1), rows.get(i));
            book.write(bytes);
            return new MockMultipartFile("file", "test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", bytes.toByteArray());
        }
    }

    @Test void previewDoesNotCreateAndImportUsesCurrentOwner() throws Exception {
        var file = file("TinDang", ListingExcelService.HEADERS, List.of(listingRow("Phòng đẹp")));
        var preview = excel.preview(8L, file);
        assertEquals(1, preview.totalRows()); assertTrue(preview.errors().isEmpty());
        verify(listings, never()).createListing(any(), any());
        assertEquals(1, excel.importListings(8L, file).importedRows());
        verify(listings).createListing(eq(8L), argThat(r -> r.getAreaId() == 6L && r.getTitle().equals("Phòng đẹp") && r.getImageUrls().size() == 1));
    }

    @Test void oneInvalidRowPreventsAllCreatesAndReportsExcelRow() throws Exception {
        var bad = listingRow("Sai giá"); bad.set(2, -1);
        var result = excel.importListings(1L, file("TinDang", ListingExcelService.HEADERS, List.of(listingRow("Đúng"), bad)));
        assertEquals(0, result.importedRows()); assertEquals(3, result.errors().get(0).row());
        verify(listings, never()).createListing(any(), any());
    }

    @Test void duplicatesUnknownAreasAndInvalidImagesAreRejected() throws Exception {
        var duplicate = listingRow("Trùng");
        assertFalse(excel.preview(1L, file("TinDang", ListingExcelService.HEADERS, List.of(duplicate, duplicate))).errors().isEmpty());
        var invalid = listingRow("Sai khu vực"); invalid.set(5, 999); invalid.set(8, "http://example.com/room.jpg");
        assertFalse(excel.preview(1L, file("TinDang", ListingExcelService.HEADERS, List.of(invalid))).errors().isEmpty());
        var existing = new ListingResponse(); existing.setTitle("Đã có"); existing.setAddress("Địa chỉ tiếng Việt");
        when(listings.getMyListings(1L)).thenReturn(List.of(existing));
        assertFalse(excel.preview(1L, file("TinDang", ListingExcelService.HEADERS, List.of(listingRow("Đã có")))).errors().isEmpty());
    }

    @Test void malformedFilesEmptyFilesAndWrongHeadersAreRejected() throws Exception {
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> excel.preview(1L, new MockMultipartFile("file", "bad.xlsx", null, new byte[]{1,2,3})));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> excel.preview(1L, file("TinDang", ListingExcelService.HEADERS, List.of())));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> excel.preview(1L, file("TinDang", List.of("Sai tiêu đề"), List.of(listingRow("A")))));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> excel.preview(1L, new MockMultipartFile("file", "test.xls", null, new byte[]{1})));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> excel.preview(1L, new MockMultipartFile("file", "big.xlsx", null, new byte[5*1024*1024+1])));
    }

    @Test void exportHasTypedValuesAndLiteralTextAndTemplateIncludesAreas() throws Exception {
        var row = new ListingResponse(); row.setTitle("=1+1"); row.setRentPrice(new java.math.BigDecimal("2500000")); row.setImageUrls(List.of("https://example.com/a.jpg"));
        when(listings.getMyListings(9L)).thenReturn(List.of(row));
        try (var book = new XSSFWorkbook(new java.io.ByteArrayInputStream(excel.exportListings(9L)))) {
            var data = book.getSheet("TinDang").getRow(1);
            assertEquals(org.apache.poi.ss.usermodel.CellType.STRING, data.getCell(0).getCellType());
            assertEquals("=1+1", data.getCell(0).getStringCellValue());
            assertEquals(2500000, data.getCell(2).getNumericCellValue());
        }
        try (var book = new XSSFWorkbook(new java.io.ByteArrayInputStream(excel.template()))) {
            assertNotNull(book.getSheet("KhuVuc")); assertNotNull(book.getSheet("HuongDan"));
            assertEquals(0, book.getSheet("TinDang").getLastRowNum());
        }
    }

    @Test void formulasAndMoreThan500RowsAreRejected() throws Exception {
        var source = file("TinDang", ListingExcelService.HEADERS, List.of(listingRow("A")));
        try (var book = new XSSFWorkbook(source.getInputStream()); var bytes = new ByteArrayOutputStream()) {
            book.getSheet("TinDang").getRow(1).getCell(2).setCellFormula("1+1");
            book.write(bytes);
            var result = excel.preview(1L, new MockMultipartFile("file", "formula.xlsx", null, bytes.toByteArray()));
            assertEquals(2, result.errors().get(0).row());
        }
        var many = Collections.nCopies(501, listingRow("A"));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> excel.preview(1L, file("TinDang", ListingExcelService.HEADERS, many)));
    }
}
