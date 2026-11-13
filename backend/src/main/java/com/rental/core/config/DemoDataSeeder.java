package com.rental.core.config;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Envelope;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.ParseException;
import org.locationtech.jts.io.WKTReader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Random;
import java.util.regex.Pattern;

/**
 * One-time opt-in demo data loader. Enable with APP_DEMO_DATA_ENABLED=true and
 * provide APP_DEMO_DATA_GMAIL_BASE with a Gmail address you control.
 */
@Component
@ConditionalOnProperty(prefix = "app.demo-data", name = "enabled", havingValue = "true")
public class DemoDataSeeder implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(DemoDataSeeder.class);
    private static final String DEMO_PASSWORD = "123456";
    private static final String PASSWORD_TAG = "demo-v1";
    private static final int PHOTOS_PER_LISTING = 5;
    private static final Pattern GMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@gmail\\.com$", Pattern.CASE_INSENSITIVE);
    private static final List<String> EMAIL_TOKENS = List.of(
            "a7k2", "m4p9", "q2x8", "v6c3", "h8n5", "r3w7", "b9f2", "t5d8", "k2z6", "p4g1");
    private static final List<String> HOUSE_IMAGES = imagePool(List.of(
            "photo-1792630862596-038e95672446", "photo-1649704584931-50d1480cf10a",
            "photo-1647579350413-a6ada4e480ed", "photo-1642447260162-8d52ac4348ad",
            "photo-1677078216410-03575e17d35c", "photo-1768941124710-1a42b3195208",
            "photo-1792172553596-efdc82ee742e", "photo-1770321119306-a9d673e485fa"));
    private static final List<String> ROOM_IMAGES = imagePool(List.of(
            "photo-1765185237761-9f42d0764304", "photo-1753911371982-dc5cafcf855b",
            "photo-1560185009-5bf9f2849488", "photo-1780662835101-efe145c028cc",
            "photo-1763792207507-de48ef19c217", "photo-1778604263874-5d9f372e0434",
            "photo-1723639907256-637c40886953", "photo-1769366316790-dfcb6a546f05",
            "photo-1793613345163-f77dcb7f9ba2"));
    private static final List<String> SHARED_IMAGES = imagePool(List.of(
            "photo-1675807526240-fb2e22e39048", "photo-1575422098125-7b0355f07f77",
            "photo-1560185009-5bf9f2849488", "photo-1778604263874-5d9f372e0434",
            "photo-1763792207507-de48ef19c217", "photo-1781512436292-f2687f67f605"));

    private static final List<DemoAccount> ACCOUNTS = List.of(
            new DemoAccount("Tài khoản mẫu 01", List.of("COOKING", "COFFEE", "PLANTS")),
            new DemoAccount("Tài khoản mẫu 02", List.of("READING", "QUIET", "NON_SMOKER")),
            new DemoAccount("Tài khoản mẫu 03", List.of("SPORTS", "TRAVEL", "COFFEE")),
            new DemoAccount("Tài khoản mẫu 04", List.of("MUSIC", "MOVIES", "SOCIABLE")),
            new DemoAccount("Tài khoản mẫu 05", List.of("COOKING", "TIDY", "EARLY_BIRD")),
            new DemoAccount("Tài khoản mẫu 06", List.of("GAMING", "MUSIC", "NIGHT_OWL")),
            new DemoAccount("Tài khoản mẫu 07", List.of("STUDY", "READING", "QUIET")),
            new DemoAccount("Tài khoản mẫu 08", List.of("DOG_LOVER", "PLANTS", "SOCIABLE")),
            new DemoAccount("Tài khoản mẫu 09", List.of("NON_SMOKER", "COOKING", "COFFEE")),
            new DemoAccount("Tài khoản mẫu 10", List.of("CAT_LOVER", "MOVIES", "TRAVEL")));

    private static final List<DemoListing> LISTINGS = List.of(
            DemoListing.house("Nhà nguyên căn hẻm rộng gần trung tâm", "Nhà 2 tầng thoáng sáng, khu dân cư yên tĩnh, có bếp riêng và chỗ để xe.", 12_500_000, 72, 2, 2, 2, "NGO_HEM", 0),
            DemoListing.house("Nhà nguyên căn có sân nhỏ, nội thất cơ bản", "Nhà sạch sẽ, phù hợp gia đình nhỏ; hợp đồng rõ ràng, có thể vào ở ngay.", 14_000_000, 84, 3, 2, 2, "LIEN_KE", 2),
            DemoListing.house("Nhà phố 3 phòng ngủ gần tiện ích", "Không gian riêng tư, gần chợ và tuyến xe buýt; ưu tiên thuê dài hạn.", 16_500_000, 96, 3, 3, 3, "MAT_PHO", 4),
            DemoListing.house("Nhà nguyên căn mới sửa, nhiều ánh sáng", "Nhà có ban công, khu bếp rộng và khu vực giặt phơi riêng.", 10_800_000, 68, 2, 2, 2, "NGO_HEM", 6),
            DemoListing.room("Phòng trọ có cửa sổ, giờ giấc tự do", "Phòng riêng, có cửa sổ đón sáng, khu vực để xe an toàn và bếp dùng chung.", 3_200_000, 22, 1, 1, 4, 0),
            DemoListing.room("Phòng trọ nội thất cơ bản, có gác", "Phòng sạch, gác lửng rộng, máy lạnh và internet; chi phí điện nước minh bạch.", 3_800_000, 25, 1, 1, 3, 2),
            DemoListing.room("Phòng cho thuê yên tĩnh gần trường học", "Phòng có nhà vệ sinh riêng, khu vực nấu ăn và chỗ gửi xe trong nhà.", 4_200_000, 28, 1, 1, 4, 4),
            DemoListing.room("Phòng trọ thoáng mát, có ban công", "Phòng đầy đủ giường, tủ và bàn làm việc; phù hợp sinh viên hoặc nhân viên văn phòng.", 4_500_000, 30, 1, 1, 5, 6),
            DemoListing.shared("Tìm một bạn nữ ở ghép, chia sẻ chi phí", "Phòng đang có một người ở, còn một chỗ; ưu tiên bạn gọn gàng, không hút thuốc.", 1_800_000, 24, 1, 2, "FEMALE", true, false, 1),
            DemoListing.shared("Tìm bạn ở ghép thân thiện, gần khu trung tâm", "Còn một chỗ trong căn hộ có bếp và máy giặt dùng chung; chi phí điện nước chia đều.", 2_100_000, 27, 1, 3, "ANY", false, false, 3));

    private final JdbcTemplate jdbc;
    private final PasswordEncoder passwordEncoder;
    private final TransactionTemplate transactionTemplate;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
    private final Random random = new Random();

    @Value("${app.demo-data.gmail-base:}")
    private String gmailBase;

    public DemoDataSeeder(JdbcTemplate jdbc, PasswordEncoder passwordEncoder,
                          PlatformTransactionManager transactionManager) {
        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.transactionTemplate = new TransactionTemplate(transactionManager);
    }

    @Override
    public void run(ApplicationArguments args) {
        String baseEmail = validateGmailBase(gmailBase);
        transactionTemplate.executeWithoutResult(status -> seed(baseEmail));
    }

    private void seed(String baseEmail) {
        List<String> emails = demoEmails(baseEmail);
        String placeholders = String.join(",", java.util.Collections.nCopies(emails.size(), "?"));
        Long existing = jdbc.queryForObject(
                "SELECT COUNT(*) FROM nguoi_dung WHERE dia_chi_thu_dien_tu IN (" + placeholders + ")",
                Long.class, emails.toArray());
        if (existing != null && existing == ACCOUNTS.size()) {
            log.info("Demo data already exists; no changes made.");
            return;
        }
        if (existing != null && existing > 0) {
            throw new IllegalStateException("Some demo email aliases already exist. Choose another Gmail base or remove the partial demo data before retrying.");
        }

        List<AreaCandidate> wards = loadDemoAreas();
        Long adminId = findAdminId();
        List<Long> userIds = new ArrayList<>(ACCOUNTS.size());
        for (int i = 0; i < ACCOUNTS.size(); i++) {
            userIds.add(insertAccount(ACCOUNTS.get(i), emails.get(i), preferredAreaName(wards)));
        }
        for (int i = 0; i < LISTINGS.size(); i++) {
            AreaCandidate area = wards.get(i % wards.size());
            insertListing(userIds.get(i), adminId, area, LISTINGS.get(i), i);
        }
        log.info("Inserted 10 verified demo accounts, 10 approved listings, 30 personal interests, and 50 listing photos.");
    }

    private List<AreaCandidate> loadDemoAreas() {
        List<AreaCandidate> all = jdbc.query("""
                SELECT a.ma_khu_vuc, a.ten_khu_vuc, COALESCE(p.ten_khu_vuc, ''),
                       ST_AsText(a.ranh_gioi_khu_vuc), ST_AsText(p.ranh_gioi_khu_vuc)
                FROM khu_vuc_hanh_chinh a
                LEFT JOIN khu_vuc_hanh_chinh p ON p.ma_khu_vuc = a.ma_khu_vuc_cap_tren
                WHERE a.cap_hanh_chinh IN ('WARD', 'COMMUNE', 'SPECIAL')
                  AND a.dang_su_dung = TRUE
                ORDER BY CASE WHEN LOWER(COALESCE(p.ten_khu_vuc, '')) LIKE '%quận 1%' THEN 0 ELSE 1 END,
                         CASE WHEN LOWER(a.ten_khu_vuc) LIKE '%bến nghé%' THEN 0 ELSE 1 END,
                         a.ma_khu_vuc
                """, (rs, row) -> new AreaCandidate(rs.getLong(1), rs.getString(2), rs.getString(3),
                rs.getString(4), rs.getString(5)));
        if (all.isEmpty()) {
            throw new IllegalStateException("No active ward-level areas are available for demo listings.");
        }
        List<AreaCandidate> districtOne = all.stream()
                .filter(area -> area.parentName().toLowerCase(Locale.ROOT).contains("quận 1"))
                .toList();
        if (!districtOne.isEmpty()) return districtOne;
        List<AreaCandidate> preferredWard = all.stream()
                .filter(area -> area.areaName().toLowerCase(Locale.ROOT).contains("bến nghé"))
                .toList();
        if (!preferredWard.isEmpty()) return preferredWard;
        return all;
    }

    private Long findAdminId() {
        List<Long> ids = jdbc.query("SELECT ma_nguoi_dung FROM nguoi_dung WHERE vai_tro = 'ADMIN' ORDER BY ma_nguoi_dung LIMIT 1",
                (rs, row) -> rs.getLong(1));
        return ids.isEmpty() ? null : ids.get(0);
    }

    private Long insertAccount(DemoAccount account, String email, String preferredArea) {
        Long userId = jdbc.queryForObject("""
                INSERT INTO nguoi_dung
                    (ho_va_ten, dia_chi_thu_dien_tu, so_dien_thoai, mat_khau_da_bam,
                     vai_tro, trang_thai, da_xac_thuc_thu_dien_tu, phien_ban_mat_khau)
                VALUES (?, ?, NULL, ?, 'MEMBER', 'ACTIVE', TRUE, 0)
                RETURNING ma_nguoi_dung
                """, Long.class, account.name(), email, passwordEncoder.encode(DEMO_PASSWORD));

        Long preferenceId = jdbc.queryForObject("""
                INSERT INTO so_thich_nguoi_dung
                    (ma_nguoi_dung, ngan_sach_toi_thieu, ngan_sach_toi_da, co_thu_cung, khu_vuc_mong_muon)
                VALUES (?, ?, ?, ?, ?)
                RETURNING ma_ho_so_so_thich
                """, Long.class, userId, 1_500_000d, 18_000_000d,
                account.interests().contains("CAT_LOVER") || account.interests().contains("DOG_LOVER"), preferredArea);
        for (String interest : account.interests()) {
            jdbc.update("INSERT INTO so_thich_da_chon (ma_ho_so_so_thich, ma_so_thich) VALUES (?, ?)", preferenceId, interest);
        }
        return userId;
    }

    private void insertListing(Long userId, Long adminId, AreaCandidate area, DemoListing listing, int index) {
        Point point = randomPoint(area);
        LocalDateTime createdAt = LocalDateTime.now().minusDays(2 + random.nextInt(26)).minusHours(random.nextInt(24));
        String address = streetFor(index) + ", " + area.areaName() + ", " + area.parentName() + ", TP. Hồ Chí Minh";
        Long listingId = jdbc.queryForObject("""
                INSERT INTO tin_cho_thue
                    (ma_chu_tin, ma_khu_vuc, ma_nguoi_duyet, tieu_de, mo_ta, loai_tin_dang,
                     gia_cho_thue, dien_tich_met_vuong, dia_chi, toa_do_vi_tri, loai_hinh_nha,
                     so_phong_ngu, so_phong_tam, tong_so_tang, huong_cua, giay_to_phap_ly,
                     tinh_trang_noi_that, tien_dat_coc, loai_nguoi_dang, trang_thai_kiem_duyet,
                     trang_thai_cho_thue, la_tin_uu_tien, so_luot_xem, thoi_diem_tao,
                     thoi_diem_cap_nhat, so_nguoi_dang_o, so_nguoi_o_toi_da,
                     yeu_cau_gioi_tinh_nguoi_o, cho_phep_nuoi_thu_cung, cho_phep_hut_thuoc,
                     yeu_cau_nguoi_o_ghep)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?, ?, ?, ?,
                        ?, ?, ?, ?, 'CA_NHAN', 'APPROVED', 'AVAILABLE', FALSE, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                RETURNING ma_tin_dang
                """, Long.class,
                userId, area.areaId(), adminId, listing.title(), listing.description(), listing.type(),
                BigDecimal.valueOf(listing.price()), BigDecimal.valueOf(listing.areaSqm()), address,
                point.getX(), point.getY(), listing.houseType(), listing.bedrooms(), listing.bathrooms(),
                listing.floors(), "Đông Nam", "Sổ hồng riêng", listing.furnished(),
                BigDecimal.valueOf(listing.price()), 8 + random.nextInt(210), createdAt, createdAt,
                listing.currentOccupants(), listing.maxOccupants(), listing.genderPreference(),
                listing.allowPets(), listing.allowSmoking(), listing.roommateRequirements());

        List<String> images = imagesFor(listing.type(), listing.imageOffset());
        for (int i = 0; i < images.size(); i++) {
            jdbc.update("""
                    INSERT INTO hinh_anh_tin_dang (ma_tin_dang, duong_dan_hinh_anh, la_anh_dai_dien, thu_tu_hien_thi)
                    VALUES (?, ?, ?, ?)
                    """, listingId, images.get(i), i == 0, i);
        }
    }

    private Point randomPoint(AreaCandidate area) {
        Geometry boundary = parseBoundary(area.areaBoundaryWkt());
        if (boundary == null) boundary = parseBoundary(area.parentBoundaryWkt());
        if (boundary != null && !boundary.isEmpty()) {
            Envelope envelope = boundary.getEnvelopeInternal();
            for (int attempt = 0; attempt < 10_000; attempt++) {
                double longitude = envelope.getMinX() + random.nextDouble() * envelope.getWidth();
                double latitude = envelope.getMinY() + random.nextDouble() * envelope.getHeight();
                Point candidate = geometryFactory.createPoint(new Coordinate(longitude, latitude));
                if (boundary.covers(candidate)) return candidate;
            }
            return boundary.getInteriorPoint();
        }

        double centerLat = 10.7780;
        double centerLon = 106.7020;
        String district = area.parentName().toLowerCase(Locale.ROOT);
        if (district.contains("bình thạnh")) { centerLat = 10.8030; centerLon = 106.7100; }
        else if (district.contains("thủ đức")) { centerLat = 10.8500; centerLon = 106.7700; }
        else if (district.contains("quận 7")) { centerLat = 10.7300; centerLon = 106.7200; }
        else if (district.contains("tân bình")) { centerLat = 10.8000; centerLon = 106.6500; }
        else if (district.contains("gò vấp")) { centerLat = 10.8400; centerLon = 106.6700; }
        double latJitter = district.contains("quận 1") ? 0.0013 : 0.0025;
        double lonJitter = district.contains("quận 1") ? 0.0015 : 0.0025;
        return geometryFactory.createPoint(new Coordinate(
                centerLon + (random.nextDouble() * 2 - 1) * lonJitter,
                centerLat + (random.nextDouble() * 2 - 1) * latJitter));
    }

    private Geometry parseBoundary(String wkt) {
        if (wkt == null || wkt.isBlank()) return null;
        try {
            return new WKTReader(geometryFactory).read(wkt);
        } catch (ParseException exception) {
            log.warn("Could not parse an administrative area boundary; using the district fallback point.");
            return null;
        }
    }

    private List<String> imagesFor(String type, int offset) {
        List<String> pool = switch (type) {
            case "WHOLE_HOUSE" -> HOUSE_IMAGES;
            case "BOARDING_ROOM" -> ROOM_IMAGES;
            default -> SHARED_IMAGES;
        };
        List<String> result = new ArrayList<>(PHOTOS_PER_LISTING);
        for (int i = 0; i < PHOTOS_PER_LISTING; i++) result.add(pool.get((offset + i) % pool.size()));
        return result;
    }

    private String preferredAreaName(List<AreaCandidate> areas) {
        AreaCandidate area = areas.get(0);
        return area.parentName().isBlank() ? area.areaName() : area.parentName();
    }

    private String streetFor(int index) {
        return List.of("Đường Nguyễn Huệ", "Đường Lê Lợi", "Đường Hàm Nghi", "Đường Đồng Khởi",
                "Đường Nguyễn Du", "Đường Hai Bà Trưng", "Đường Mạc Thị Bưởi", "Đường Pasteur",
                "Đường Tôn Đức Thắng", "Đường Nguyễn Thị Minh Khai").get(index % 10);
    }

    private List<String> demoEmails(String baseEmail) {
        String localPart = baseEmail.substring(0, baseEmail.indexOf('@')).split("\\+", 2)[0];
        String tag = shortHash(baseEmail + PASSWORD_TAG);
        List<String> emails = new ArrayList<>(ACCOUNTS.size());
        for (int i = 0; i < EMAIL_TOKENS.size(); i++) {
            emails.add(localPart + "+demo-" + tag.substring(0, 4) + EMAIL_TOKENS.get(i) + "@gmail.com");
        }
        return emails;
    }

    private String validateGmailBase(String value) {
        if (value == null || !GMAIL_PATTERN.matcher(value.trim()).matches()) {
            throw new IllegalStateException("APP_DEMO_DATA_GMAIL_BASE must be a Gmail address you control.");
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private static String shortHash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest).substring(0, 8);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable.", exception);
        }
    }

    private static List<String> imagePool(List<String> photoIds) {
        return photoIds.stream()
                .map(id -> "https://images.unsplash.com/" + id + "?auto=format&fit=crop&w=1200&q=80")
                .toList();
    }

    private record DemoAccount(String name, List<String> interests) {}

    private record AreaCandidate(long areaId, String areaName, String parentName,
                                 String areaBoundaryWkt, String parentBoundaryWkt) {}

    private record DemoListing(String title, String description, String type, double price, double areaSqm,
                               String houseType, Integer bedrooms, Integer bathrooms, Integer floors,
                               Integer currentOccupants, Integer maxOccupants, String genderPreference,
                               Boolean allowPets, Boolean allowSmoking, String roommateRequirements,
                               String furnished, int imageOffset) {
        static DemoListing house(String title, String description, double price, double areaSqm,
                                 int bedrooms, int bathrooms, int floors, String houseType, int imageOffset) {
            return new DemoListing(title, description, "WHOLE_HOUSE", price, areaSqm, houseType,
                    bedrooms, bathrooms, floors, null, null, null, null, null, null,
                    "Nội thất cơ bản", imageOffset);
        }

        static DemoListing room(String title, String description, double price, double areaSqm,
                                int bedrooms, int bathrooms, int floors, int imageOffset) {
            return new DemoListing(title, description, "BOARDING_ROOM", price, areaSqm, "NGO_HEM",
                    bedrooms, bathrooms, floors, null, null, null, null, null, null,
                    "Đầy đủ", imageOffset);
        }

        static DemoListing shared(String title, String description, double price, double areaSqm,
                                  int currentOccupants, int maxOccupants, String genderPreference,
                                  boolean allowPets, boolean allowSmoking, int imageOffset) {
            return new DemoListing(title, description, "SHARED_ROOM", price, areaSqm, "NGO_HEM",
                    1, 1, 1, currentOccupants, maxOccupants, genderPreference, allowPets,
                    allowSmoking, "Ưu tiên người ở gọn gàng, tôn trọng không gian chung.",
                    "Đầy đủ", imageOffset);
        }
    }
}
