package com.rental.modules.listing.service;

import com.rental.modules.area.repository.AdministrativeAreaRepository;
import com.rental.modules.listing.dto.request.CreateListingRequest;
import com.rental.core.excel.ExcelImportResult;
import com.rental.modules.listing.dto.response.ListingResponse;
import jakarta.validation.Validator;
import org.apache.poi.ss.usermodel.*;
import static com.rental.core.excel.ExcelWorkbook.writeRow;
import static com.rental.core.excel.ExcelWorkbook.style;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.*;

@Service
@Transactional(readOnly = true)
public class ListingExcelService {
    public static final List<String> HEADERS = List.of(
        "Tiêu đề", "Loại tin", "Giá thuê", "Diện tích", "Địa chỉ", "Mã khu vực", "Vĩ độ", "Kinh độ",
        "Link ảnh", "Mô tả", "Tiền cọc", "Loại nhà", "Phòng ngủ", "Phòng tắm", "Số tầng", "Hướng cửa",
        "Pháp lý", "Nội thất", "Người đăng", "Đang ở", "Tối đa", "Giới tính", "Nuôi thú cưng", "Hút thuốc", "Yêu cầu ở ghép");
    private static final List<String> FIELDS = List.of(
        "title", "listingType", "rentPrice", "areaSqm", "address", "areaId", "latitude", "longitude",
        "imageUrls", "description", "depositAmount", "houseType", "bedrooms", "bathrooms", "totalFloors", "doorDirection",
        "legalDocuments", "furnitureStatus", "posterType", "currentOccupants", "maxOccupants", "genderPreference", "allowPets", "allowSmoking", "roommateRequirements");
    private final ListingService listings;
    private final AdministrativeAreaRepository areas;
    private final Validator validator;

    public ListingExcelService(ListingService listings, AdministrativeAreaRepository areas, Validator validator) {
        this.listings = listings;
        this.areas = areas;
        this.validator = validator;
    }

    public byte[] template() {
        return workbook(List.of(), true);
    }

    public byte[] exportListings(Long ownerId) {
        return workbook(listings.getMyListings(ownerId), false);
    }

    public ExcelImportResult preview(Long ownerId, MultipartFile file) {
        return read(ownerId, file).result(0);
    }

    @Transactional
    public ExcelImportResult importListings(Long ownerId, MultipartFile file) {
        Parsed parsed = read(ownerId, file);
        if (!parsed.errors.isEmpty()) return parsed.result(0);
        for (CreateListingRequest request : parsed.requests) {
            listings.createListing(ownerId, request);
        }
        return parsed.result(parsed.requests.size());
    }

    private byte[] workbook(List<ListingResponse> rows, boolean template) {
        try (var book = new XSSFWorkbook(); var output = new ByteArrayOutputStream()) {
            var sheet = book.createSheet("TinDang");
            var headers = new ArrayList<>(HEADERS);
            headers.addAll(List.of("Mã tin (chỉ xem)", "Kiểm duyệt (chỉ xem)", "Cho thuê (chỉ xem)"));
            writeRow(sheet.createRow(0), headers);
            for (ListingResponse row : rows) writeRow(sheet.createRow(sheet.getLastRowNum() + 1), values(row));
            style(book, sheet, headers.size());
            if (template) addAreas(book);
            var help = book.createSheet("HuongDan");
            List<String> notes = List.of(
                "Chỉ sửa dữ liệu trong sheet TinDang. Không thay đổi hàng tiêu đề. Mỗi dòng tạo một tin mới, không cập nhật tin cũ.",
                "Tối đa 500 tin/file .xlsx, tối đa 5 MB. Có dòng lỗi thì toàn bộ file chưa được nhập. Tin mới luôn chờ Admin duyệt.",
                "Bắt buộc: Tiêu đề, Loại tin, Giá thuê, Diện tích, Địa chỉ, Mã khu vực, Vĩ độ, Kinh độ, Link ảnh.",
                "Loại tin: WHOLE_HOUSE = nhà nguyên căn; BOARDING_ROOM = phòng trọ; SHARED_ROOM = tìm người ở ghép.",
                "Giá thuê/tiền cọc dùng VND; diện tích dùng m². Nhập số thuần, ví dụ 2500000 và 25.5; không kèm đơn vị.",
                "Tra Mã khu vực ở sheet KhuVuc của file mẫu. Mã này là ID hệ thống, không phải mã hành chính quốc gia.",
                "Vĩ độ từ -90 đến 90; kinh độ từ -180 đến 180. Ví dụ 10.78 và 106.7.",
                "Link ảnh: 1–10 địa chỉ HTTPS, ngăn cách bằng dấu |. Ví dụ https://example.com/1.jpg|https://example.com/2.jpg.",
                "Tin ở ghép bắt buộc có Đang ở, Tối đa (lớn hơn Đang ở, tối đa 20), Giới tính (ANY/MALE/FEMALE).",
                "Nuôi thú cưng/Hút thuốc: TRUE hoặc FALSE (có thể để trống). Các cột còn lại không bắt buộc.",
                "Mã tin, Kiểm duyệt, Cho thuê là thông tin xuất để xem; không được dùng để đổi quyền sở hữu hay trạng thái khi nhập.",
                "Không nhập công thức Excel. Các dòng trùng tiêu đề và địa chỉ trong file hoặc với tin đang quản lý sẽ bị báo lỗi.");
            for (int i = 0; i < notes.size(); i++) help.createRow(i).createCell(0).setCellValue(notes.get(i));
            help.setColumnWidth(0, 120 * 256);
            book.write(output);
            return output.toByteArray();
        } catch (java.io.IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Không tạo được file Excel.");
        }
    }

    private List<Object> values(ListingResponse l) {
        return Arrays.asList(l.getTitle(), l.getListingType(), l.getRentPrice(), l.getAreaSqm(), l.getAddress(),
            l.getAreaId(), l.getLatitude(), l.getLongitude(), String.join("|", l.getImageUrls() == null ? List.of() : l.getImageUrls()),
            l.getDescription(), l.getDepositAmount(), l.getHouseType(), l.getBedrooms(), l.getBathrooms(), l.getTotalFloors(),
            l.getDoorDirection(), l.getLegalDocuments(), l.getFurnitureStatus(), l.getPosterType(), l.getCurrentOccupants(),
            l.getMaxOccupants(), l.getGenderPreference(), l.getAllowPets(), l.getAllowSmoking(), l.getRoommateRequirements(),
            l.getId(), l.getApprovalStatus(), l.getRentalStatus());
    }





    private void addAreas(Workbook book) {
        var sheet = book.createSheet("KhuVuc");
        writeRow(sheet.createRow(0), List.of("Mã khu vực", "Phường / xã / đặc khu", "Tỉnh / thành phố"));
        var all = areas.findAll();
        Map<Long, String> names = new HashMap<>();
        for (var area : all) names.put(area.getAreaId(), area.getAreaName());
        for (var area : all) {
            if (!List.of("WARD", "COMMUNE", "SPECIAL").contains(area.getAreaType() == null ? "" : area.getAreaType())) continue;
            String parent = area.getParent() == null ? "" : names.getOrDefault(area.getParent().getAreaId(), "");
            writeRow(sheet.createRow(sheet.getLastRowNum() + 1), List.of(area.getAreaId(), area.getAreaName(), parent));
        }
        style(book, sheet, 3);
    }

    private Parsed read(Long ownerId, MultipartFile file) {
        String name = file.getOriginalFilename();
        if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024 || name == null || !name.toLowerCase(Locale.ROOT).endsWith(".xlsx")) {
            throw bad("Chọn file .xlsx không rỗng, dung lượng tối đa 5 MB.");
        }
        Parsed parsed = new Parsed();
        Set<String> known = new HashSet<>();
        for (var existing : listings.getMyListings(ownerId)) known.add(key(existing.getTitle(), existing.getAddress()));
        Set<Long> validAreas = new HashSet<>();
        for (var area : areas.findAll()) {
            if (List.of("WARD", "COMMUNE", "SPECIAL").contains(area.getAreaType() == null ? "" : area.getAreaType())) validAreas.add(area.getAreaId());
        }
        try (var input = file.getInputStream(); var book = new XSSFWorkbook(input)) {
            Sheet sheet = book.getSheet("TinDang");
            if (sheet == null || sheet.getRow(0) == null) throw bad("Thiếu sheet TinDang hoặc hàng tiêu đề. Hãy tải lại file mẫu.");
            if (sheet.getLastRowNum() > 500) throw bad("Mỗi file chỉ được chứa tối đa 500 dòng dữ liệu.");
            for (int c = 0; c < HEADERS.size(); c++) {
                if (!HEADERS.get(c).equals(text(sheet.getRow(0), c))) throw bad("Sai cột " + (c + 1) + ": cần là “" + HEADERS.get(c) + "”.");
            }
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (empty(row)) continue;
                parsed.total++;
                try {
                    CreateListingRequest request = request(row);
                    List<String> errors = validate(request, validAreas, known);
                    if (!errors.isEmpty()) {
                        parsed.errors.add(new ExcelImportResult.RowError(i + 1, String.join("; ", errors)));
                        continue;
                    }
                    known.add(key(request.getTitle(), request.getAddress()));
                    parsed.requests.add(request);
                    parsed.rows.add(new ExcelImportResult.RowPreview(i + 1, request.getTitle(), request.getAddress()));
                } catch (IllegalArgumentException ex) {
                    parsed.errors.add(new ExcelImportResult.RowError(i + 1, ex.getMessage()));
                }
            }
            if (parsed.total == 0) throw bad("File chưa có tin đăng nào để nhập.");
            return parsed;
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw bad("Không đọc được Excel. Hãy dùng file mẫu .xlsx, không đặt mật khẩu và không dùng công thức.");
        }
    }

    private List<String> validate(CreateListingRequest request, Set<Long> validAreas, Set<String> known) {
        Set<String> errors = new TreeSet<>();
        for (var error : validator.validate(request)) {
            int column = FIELDS.indexOf(error.getPropertyPath().toString().split("\\[")[0]);
            errors.add(column < 0 ? "Thông tin ở ghép không hợp lệ." : HEADERS.get(column) + ": thiếu hoặc không hợp lệ.");
        }
        if (!validAreas.contains(request.getAreaId())) errors.add("Mã khu vực không hợp lệ. Tra sheet KhuVuc trong file mẫu.");
        if (known.contains(key(request.getTitle(), request.getAddress()))) errors.add("Trùng tiêu đề và địa chỉ với tin đã có hoặc dòng phía trên.");
        return new ArrayList<>(errors);
    }

    private CreateListingRequest request(Row row) {
        var r = new CreateListingRequest();
        r.setTitle(text(row, 0)); r.setListingType(text(row, 1)); r.setRentPrice(decimal(row, 2)); r.setAreaSqm(decimal(row, 3));
        r.setAddress(text(row, 4));
        BigDecimal area = decimal(row, 5);
        try { r.setAreaId(area == null ? null : area.longValueExact()); }
        catch (ArithmeticException e) { throw new IllegalArgumentException("Mã khu vực phải là số nguyên."); }
        r.setLatitude(coordinate(row, 6)); r.setLongitude(coordinate(row, 7));
        String images = text(row, 8);
        r.setImageUrls(images == null ? List.of() : Arrays.asList(images.split("\\|", -1)));
        r.setDescription(text(row, 9)); r.setDepositAmount(decimal(row, 10)); r.setHouseType(text(row, 11));
        r.setBedrooms(integer(row, 12)); r.setBathrooms(integer(row, 13)); r.setTotalFloors(integer(row, 14));
        r.setDoorDirection(text(row, 15)); r.setLegalDocuments(text(row, 16)); r.setFurnitureStatus(text(row, 17));
        r.setPosterType(text(row, 18)); r.setCurrentOccupants(integer(row, 19)); r.setMaxOccupants(integer(row, 20));
        r.setGenderPreference(text(row, 21)); r.setAllowPets(bool(row, 22)); r.setAllowSmoking(bool(row, 23)); r.setRoommateRequirements(text(row, 24));
        return r;
    }

    private String text(Row row, int column) {
        Cell cell = row.getCell(column);
        if (cell == null || cell.getCellType() == CellType.BLANK) return null;
        if (cell.getCellType() == CellType.FORMULA || cell.getCellType() == CellType.ERROR) throw new IllegalArgumentException("Cột " + HEADERS.get(column) + " không được chứa công thức hoặc lỗi Excel.");
        String value = new DataFormatter(Locale.ROOT).formatCellValue(cell).trim();
        if (cell.getCellType() == CellType.NUMERIC) value = BigDecimal.valueOf(cell.getNumericCellValue()).stripTrailingZeros().toPlainString();
        return value.isEmpty() ? null : value;
    }

    private BigDecimal decimal(Row row, int column) {
        String value = text(row, column);
        if (value == null) return null;
        try { return new BigDecimal(value); }
        catch (NumberFormatException e) { throw new IllegalArgumentException(HEADERS.get(column) + " phải là số, dùng dấu chấm cho phần thập phân."); }
    }

    private Integer integer(Row row, int column) {
        BigDecimal value = decimal(row, column);
        try { return value == null ? null : value.intValueExact(); }
        catch (ArithmeticException e) { throw new IllegalArgumentException(HEADERS.get(column) + " phải là số nguyên."); }
    }

    private Double coordinate(Row row, int column) {
        BigDecimal value = decimal(row, column);
        if (value == null) return null;
        double number = value.doubleValue();
        if (!Double.isFinite(number)) throw new IllegalArgumentException(HEADERS.get(column) + " không hợp lệ.");
        return number;
    }

    private Boolean bool(Row row, int column) {
        String value = text(row, column);
        if (value == null) return null;
        if ("TRUE".equalsIgnoreCase(value)) return true;
        if ("FALSE".equalsIgnoreCase(value)) return false;
        throw new IllegalArgumentException(HEADERS.get(column) + " chỉ nhận TRUE hoặc FALSE.");
    }

    private boolean empty(Row row) {
        if (row == null) return true;
        for (int i = 0; i < HEADERS.size(); i++) {
            Cell cell = row.getCell(i);
            if (cell != null && cell.getCellType() != CellType.BLANK
                && !(cell.getCellType() == CellType.STRING && cell.getStringCellValue().isBlank())) return false;
        }
        return true;
    }

    private String key(String title, String address) {
        return (title + "\n" + address).trim().toLowerCase(Locale.ROOT);
    }

    private ResponseStatusException bad(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }

    private static class Parsed {
        int total;
        final List<CreateListingRequest> requests = new ArrayList<>();
        final List<ExcelImportResult.RowPreview> rows = new ArrayList<>();
        final List<ExcelImportResult.RowError> errors = new ArrayList<>();
        ExcelImportResult result(int imported) { return new ExcelImportResult(total, imported, rows, errors); }
    }
}
