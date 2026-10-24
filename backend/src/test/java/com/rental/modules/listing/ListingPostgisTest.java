package com.rental.modules.listing;

import com.rental.modules.admin.service.AdminListingService;
import com.rental.modules.listing.dto.request.CreateListingRequest;
import com.rental.modules.listing.service.ListingService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.repository.UserRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.math.BigDecimal;
import java.sql.DriverManager;
import java.util.List;
import java.util.Properties;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/** Opt-in integration check using an isolated, disposable schema on local PostGIS. */
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import({com.rental.modules.admin.service.AdminAreaService.class, com.rental.modules.admin.service.AdminCreateUserService.class, com.rental.modules.user.service.OtpService.class, com.rental.modules.admin.service.AdminUserService.class, com.rental.modules.notification.service.NotificationService.class, ListingService.class, com.rental.modules.listing.service.ListingExcelService.class,
        com.rental.modules.contract.service.ContractExcelService.class, com.rental.modules.contract.service.ContractExcelWriter.class,
        org.springframework.boot.autoconfigure.validation.ValidationAutoConfiguration.class, AdminListingService.class, com.rental.modules.area.service.AreaService.class,
        com.rental.modules.property.service.PropertyService.class,
        com.rental.modules.favorite.service.ListingFavoriteService.class,
        com.rental.modules.contract.service.ContractService.class, com.rental.modules.contract.service.ContractDocumentService.class, com.rental.modules.user.service.UserService.class})
@EnabledIfEnvironmentVariable(named = "RENTAL_POSTGIS_TESTS", matches = "true")
class ListingPostgisTest {
    private static final String SCHEMA = "listing_flow_" + UUID.randomUUID().toString().replace("-", "");
    private static Properties configuration;
    private static boolean created;

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) throws Exception {
        var yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yml"));
        configuration = yaml.getObject();
        String configuredUrl = configuration.getProperty("spring.datasource.url");
        if (!configuredUrl.matches("jdbc:postgresql://(127\\.0\\.0\\.1|localhost):[0-9]+/.*")) {
            throw new IllegalStateException("PostGIS integration tests require a local development database");
        }
        try (var connection = DriverManager.getConnection(configuration.getProperty("spring.datasource.url"),
                configuration.getProperty("spring.datasource.username"), configuration.getProperty("spring.datasource.password"));
             var statement = connection.createStatement()) {
            statement.execute("CREATE SCHEMA " + SCHEMA);
            created = true;
        }
        String baseUrl = configuration.getProperty("spring.datasource.url");
        registry.add("spring.datasource.url", () -> baseUrl + (baseUrl.contains("?") ? "&" : "?") + "currentSchema=" + SCHEMA + ",public");
        registry.add("spring.flyway.schemas", () -> SCHEMA);
        registry.add("spring.flyway.default-schema", () -> SCHEMA);
        registry.add("spring.flyway.baseline-on-migrate", () -> "false");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
    }

    @AfterAll static void cleanup() throws Exception {
        if (!created) return;
        if (!SCHEMA.matches("listing_flow_[a-f0-9]{32}")) throw new IllegalStateException("Unexpected test schema");
        try (var connection = DriverManager.getConnection(configuration.getProperty("spring.datasource.url"),
                configuration.getProperty("spring.datasource.username"), configuration.getProperty("spring.datasource.password"));
             var statement = connection.createStatement()) {
            statement.execute("DROP SCHEMA " + SCHEMA + " CASCADE");
        }
    }

    @Autowired com.rental.modules.admin.service.AdminAreaService adminAreas;

    @Test void adminAreaCrudSearchAndPaginationUseRealDatabase() {
        var province = adminAreas.create(new com.rental.modules.admin.dto.request.AdminAreaRequest("Tỉnh kiểm thử", "PROVINCE", "TEST-P", null));
        for (int i = 0; i < 22; i++) {
            adminAreas.create(new com.rental.modules.admin.dto.request.AdminAreaRequest("Xã kiểm thử " + i, "COMMUNE", "TEST-C-" + i, province.id()));
        }
        var page = adminAreas.search("KIỂM THỬ", "COMMUNE", province.id(), true, 0);
        assertEquals(22, page.total()); assertEquals(20, page.items().size()); assertEquals(2, page.totalPages());
        assertEquals(2, adminAreas.search("", "COMMUNE", province.id(), true, 1).items().size());
        assertEquals(0, adminAreas.search("%", null, null, null, 0).total());
        assertEquals(22, adminAreas.detail(province.id()).children());
        assertTrue(adminAreas.parents().stream().anyMatch(p -> p.id().equals(province.id())));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.create(
            new com.rental.modules.admin.dto.request.AdminAreaRequest("Tên khác", "PROVINCE", "test-p", null)));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.create(
            new com.rental.modules.admin.dto.request.AdminAreaRequest("  Tỉnh kiểm thử  ", "PROVINCE", "TEST-DUP", null)));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.create(
            new com.rental.modules.admin.dto.request.AdminAreaRequest("Sai cấp", "COMMUNE", "TEST-BAD", page.items().get(0).id())));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.create(
            new com.rental.modules.admin.dto.request.AdminAreaRequest("Quận mới", "DISTRICT", "TEST-D", province.id())));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.update(province.id(),
            new com.rental.modules.admin.dto.request.AdminAreaRequest("Tỉnh kiểm thử", "WARD", "TEST-P", province.id())));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.search("", "INVALID", null, null, 0));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.search("", null, null, null, -1));
    }

    @Test void adminAreaActivationRespectsHierarchyAndDeletionKeepsReferences() {
        var province = adminAreas.create(new com.rental.modules.admin.dto.request.AdminAreaRequest("Tỉnh trạng thái", "PROVINCE", "STATUS-P", null));
        var ward = adminAreas.create(new com.rental.modules.admin.dto.request.AdminAreaRequest("Phường trạng thái", "WARD", "STATUS-W", province.id()));
        assertTrue(areas.getAllProvinces().stream().anyMatch(p -> p.getId().equals(province.id())));
        assertEquals(1, areas.getWardsByProvince(province.id()).size());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.changeStatus(province.id(), false));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.delete(province.id()));
        adminAreas.changeStatus(ward.id(), false);
        assertTrue(areas.getWardsByProvince(province.id()).isEmpty());
        adminAreas.changeStatus(province.id(), false);
        assertTrue(areas.getAllProvinces().stream().noneMatch(p -> p.getId().equals(province.id())));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.changeStatus(ward.id(), true));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.create(
            new com.rental.modules.admin.dto.request.AdminAreaRequest("Xã không hợp lệ", "COMMUNE", "STATUS-NEW", province.id())));
        adminAreas.changeStatus(province.id(), true); adminAreas.changeStatus(ward.id(), true);
        assertEquals(1, areas.getWardsByProvince(province.id()).size());
        adminAreas.delete(ward.id()); adminAreas.delete(province.id());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.detail(ward.id()));
    }

    @Test void disabledAreasBlockNewListingsAndExcelButKeepExistingListings() throws Exception {
        User owner = user("areaowner", Role.MEMBER), reviewer = user("areaadmin", Role.ADMIN);
        CreateListingRequest request = new CreateListingRequest();
        request.setTitle("Tin giữ dữ liệu khu vực"); request.setListingType("WHOLE_HOUSE"); request.setAreaId(6L);
        request.setAddress("TP.HCM"); request.setAreaSqm(new BigDecimal("40")); request.setRentPrice(new BigDecimal("4000000"));
        request.setLatitude(10.78); request.setLongitude(106.7); request.setImageUrls(List.of("https://example.com/area.jpg"));
        Long listingId = listings.createListing(owner.getUserId(), request).getId();
        admin.approveListing(listingId, reviewer.getUserId());
        var propertyRequest = new com.rental.modules.property.dto.request.PropertyRequest(
            "Khu trọ giữ dữ liệu", "", "Địa chỉ", 1L, 2L, 6L, "BOARDING_HOUSE",
            BigDecimal.ZERO, BigDecimal.ZERO, List.of());
        var property = properties.createProperty(owner.getEmail(), propertyRequest);
        entityManager.flush();
        assertEquals(1, adminAreas.detail(6L).listingCount());
        assertEquals(1, adminAreas.detail(6L).propertyCount());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.delete(6L));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminAreas.update(6L,
            new com.rental.modules.admin.dto.request.AdminAreaRequest("Phường Bến Nghé", "WARD", "BN", 1L)));
        jdbc.update("UPDATE administrative_areas SET boundary=ST_GeomFromText('POLYGON((106 10,107 10,107 11,106 10))',4326) WHERE area_id=6");
        var renamed = adminAreas.update(6L, new com.rental.modules.admin.dto.request.AdminAreaRequest("Phường đã đổi tên", "WARD", "BN", 2L));
        assertEquals("Phường đã đổi tên", renamed.name());
        assertNotNull(jdbc.queryForObject("SELECT ST_AsText(boundary) FROM administrative_areas WHERE area_id=6", String.class));
        adminAreas.changeStatus(6L, false);
        assertTrue(areas.getWardsByDistrict(2L).stream().noneMatch(w -> w.getId().equals(6L)));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> listings.createListing(owner.getUserId(), request));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> properties.createProperty(owner.getEmail(), propertyRequest));
        assertEquals(1L, jdbc.queryForObject("SELECT count(*) FROM properties WHERE id=?", Long.class, property.getId()));
        var file = ListingExcelTest.file("TinDang", com.rental.modules.listing.service.ListingExcelService.HEADERS, List.of(ListingExcelTest.listingRow("Tin không hợp lệ")));
        assertFalse(listingExcel.preview(owner.getUserId(), file).errors().isEmpty());
        assertEquals(1L, jdbc.queryForObject("SELECT count(*) FROM listings WHERE listing_id=?", Long.class, listingId));
        assertEquals(listingId, listings.getPublicListing(listingId).getId());
        try (var book = new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(listingExcel.template()))) {
            var sheet = book.getSheet("KhuVuc");
            for (int row = 1; row <= sheet.getLastRowNum(); row++) {
                assertNotEquals(6.0, sheet.getRow(row).getCell(0).getNumericCellValue());
            }
        }
        adminAreas.changeStatus(6L, true);
        assertTrue(areas.getWardsByDistrict(2L).stream().anyMatch(w -> w.getId().equals(6L)));
    }

    @Autowired com.rental.modules.admin.service.AdminCreateUserService adminCreation;
    @Autowired com.rental.modules.user.service.OtpService adminOtp;
    @org.springframework.boot.test.mock.mockito.MockBean com.rental.modules.user.service.EmailService adminEmail;
    @org.springframework.boot.test.mock.mockito.MockBean org.springframework.security.crypto.password.PasswordEncoder adminPasswords;

    @Test
    @org.springframework.transaction.annotation.Transactional(propagation = org.springframework.transaction.annotation.Propagation.NOT_SUPPORTED)
    void adminCreationCommitsOnlyWhenOtpMailSucceeds() {
        var encoder = new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder();
        org.mockito.Mockito.when(adminPasswords.encode(org.mockito.ArgumentMatchers.anyString()))
            .thenAnswer(call -> encoder.encode(call.getArgument(0)));
        String successEmail = "admincreated@example.com", failedEmail = "failedcreation@example.com";
        try {
            var request = new com.rental.modules.admin.dto.request.AdminCreateUserRequest(
                "Người dùng mới", successEmail, null, "Password123!", Role.MEMBER);
            var created = adminCreation.create(request);
            User stored = users.findById(created.id()).orElseThrow();
            assertFalse(stored.getIsVerified()); assertEquals(Role.MEMBER, stored.getRole());
            assertTrue(encoder.matches("Password123!", stored.getPasswordHash()));
            var successCode = org.mockito.ArgumentCaptor.forClass(String.class);
            org.mockito.Mockito.verify(adminEmail).sendOtpEmail(org.mockito.ArgumentMatchers.eq(successEmail), successCode.capture());
            var provider = new org.springframework.security.authentication.dao.DaoAuthenticationProvider();
            provider.setUserDetailsService(new com.rental.core.security.CustomUserDetailsService(users));
            provider.setPasswordEncoder(encoder);
            var manager = new org.springframework.security.authentication.ProviderManager(provider);
            var jwt = org.mockito.Mockito.mock(com.rental.core.security.JwtService.class);
            org.mockito.Mockito.when(jwt.generateAccessToken(org.mockito.ArgumentMatchers.any())).thenReturn("verified-access");
            var auth = new com.rental.modules.user.service.AuthService(users, encoder, adminOtp, adminEmail, manager, jwt);
            var login = new com.rental.modules.user.dto.request.LoginRequest(successEmail, "Password123!");
            assertThrows(IllegalStateException.class, () -> auth.login(login));
            auth.verifyOtp(new com.rental.modules.user.dto.request.VerifyOtpRequest(successEmail, successCode.getValue()));
            assertEquals(created.id(), auth.login(login).getUserId());
            assertEquals("verified-access", auth.login(login).getAccessToken());
            assertFalse(adminOtp.validateOtp(successEmail, successCode.getValue()));
            org.mockito.Mockito.doThrow(new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                .when(adminEmail).sendOtpEmail(org.mockito.ArgumentMatchers.eq(failedEmail), org.mockito.ArgumentMatchers.anyString());
            var failedRequest = new com.rental.modules.admin.dto.request.AdminCreateUserRequest(
                "Mail failed", failedEmail, "0909999888", "Password123!", Role.MEMBER);
            assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> adminCreation.create(failedRequest));
            assertFalse(users.existsByEmailIgnoreCase(failedEmail));
            assertTrue(users.findByPhoneNumber("0909999888").isEmpty());
            var failedCode = org.mockito.ArgumentCaptor.forClass(String.class);
            org.mockito.Mockito.verify(adminEmail).sendOtpEmail(org.mockito.ArgumentMatchers.eq(failedEmail), failedCode.capture());
            assertFalse(adminOtp.validateOtp(failedEmail, failedCode.getValue()));
        } finally {
            users.findByEmail(successEmail).ifPresent(users::delete);
            users.findByEmail(failedEmail).ifPresent(users::delete);
        }
    }

    @Autowired com.rental.modules.admin.service.AdminUserService adminUsers;

    @Test void adminUserSearchPaginationEditsAndLocksWorkWithRealDatabase() {
        User admin = user("managementadmin", Role.ADMIN);
        for (int index = 0; index < 23; index++) user("managementtenant" + index, Role.MEMBER);
        var first = adminUsers.search("MANAGEMENTTENANT", null, null, null, 0);
        assertEquals(23, first.total()); assertEquals(20, first.items().size()); assertEquals(2, first.totalPages());
        assertEquals(3, adminUsers.search("managementtenant", Role.MEMBER, UserStatus.ACTIVE, true, 1).items().size());
        User target = users.findByEmail("managementtenant0@example.com").orElseThrow();
        adminUsers.update(target.getUserId(), admin.getUserId(),
            new com.rental.modules.admin.dto.request.AdminUpdateUserRequest("Người dùng mới", "0901234567", Role.MEMBER));
        adminUsers.changeStatus(target.getUserId(), admin.getUserId(), UserStatus.LOCKED);
        entityManager.flush(); entityManager.clear();
        var match = adminUsers.search("090123", Role.MEMBER, UserStatus.LOCKED, true, 0);
        assertEquals(1, match.total()); assertEquals("Người dùng mới", match.items().get(0).fullName());
        assertEquals(0, adminUsers.search("090123", Role.ADMIN, null, null, 0).total());
        assertEquals(24, adminUsers.search("", null, null, null, 0).total());
        assertEquals(0, adminUsers.search("%", null, null, null, 0).total());
        target = users.findById(target.getUserId()).orElseThrow(); target.setIsVerified(false); users.saveAndFlush(target);
        adminUsers.changeStatus(target.getUserId(), admin.getUserId(), UserStatus.ACTIVE);
        assertEquals(0, adminUsers.search("090123", null, null, true, 0).total());
        assertEquals(1, adminUsers.search("090123", null, UserStatus.ACTIVE, false, 0).total());
    }

    @Autowired com.rental.modules.listing.service.ListingExcelService listingExcel;
    @Autowired com.rental.modules.contract.service.ContractExcelService contractExcel;

    @Test void excelImportsCreatePendingListingsAndDraftContractsWithRealDatabase() throws Exception {
        User owner = user("excelowner", Role.MEMBER), tenant = user("exceltenant", Role.MEMBER), reviewer = user("exceladmin", Role.ADMIN);
        tenant.setPhoneNumber("0901234567"); users.saveAndFlush(tenant);
        var row = ListingExcelTest.listingRow("Tin từ Excel");
        var file = ListingExcelTest.file("TinDang", com.rental.modules.listing.service.ListingExcelService.HEADERS, List.of(row));
        var invalidRow = ListingExcelTest.listingRow("Sai giá từ Excel"); invalidRow.set(2, -1);
        var invalidFile = ListingExcelTest.file("TinDang", com.rental.modules.listing.service.ListingExcelService.HEADERS, List.of(row, invalidRow));
        assertEquals(0, listingExcel.importListings(owner.getUserId(), invalidFile).importedRows());
        assertTrue(listings.getMyListings(owner.getUserId()).isEmpty());
        assertTrue(listingExcel.preview(owner.getUserId(), file).errors().isEmpty());
        assertTrue(listings.getMyListings(owner.getUserId()).isEmpty());
        assertEquals(1, listingExcel.importListings(owner.getUserId(), file).importedRows());
        entityManager.flush(); entityManager.clear();
        var created = listings.getMyListings(owner.getUserId()).get(0);
        assertEquals("PENDING", created.getApprovalStatus());
        assertTrue(listings.getMyListings(tenant.getUserId()).isEmpty());
        assertFalse(listingExcel.importListings(owner.getUserId(), file).errors().isEmpty());
        try (var book = new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(listingExcel.exportListings(owner.getUserId())))) {
            assertEquals("Tin từ Excel", book.getSheet("TinDang").getRow(1).getCell(0).getStringCellValue());
        }
        admin.approveListing(created.getId(), reviewer.getUserId());
        entityManager.flush(); entityManager.clear();
        var contractRow = new java.util.ArrayList<Object>(java.util.Arrays.asList(created.getId(), "0901234567", "2027-01-01", "2028-01-01", 2500000, 1000000, "Excel",
            "001234567890", "Địa chỉ chủ nhà", "009876543210", "Địa chỉ người thuê", "TP.HCM", "2027-01-01", "2027-01-01", "Chuyển khoản", "Theo hóa đơn", "Theo hóa đơn"));
        var contractFile = ListingExcelTest.file("HopDong", com.rental.modules.contract.service.ContractExcelService.HEADERS, List.of(contractRow));
        var duplicateContracts = ListingExcelTest.file("HopDong", com.rental.modules.contract.service.ContractExcelService.HEADERS, List.of(contractRow, contractRow));
        assertEquals(0, contractExcel.importContracts(owner.getEmail(), owner.getUserId(), duplicateContracts).importedRows());
        assertTrue(leases.getMyContracts(owner.getEmail()).isEmpty());
        assertTrue(contractExcel.preview(owner.getEmail(), owner.getUserId(), contractFile).errors().isEmpty());
        assertTrue(leases.getMyContracts(owner.getEmail()).isEmpty());
        assertEquals(1, contractExcel.importContracts(owner.getEmail(), owner.getUserId(), contractFile).importedRows());
        entityManager.flush(); entityManager.clear();
        var draft = leases.getMyContracts(owner.getEmail()).get(0);
        assertEquals("DRAFT", draft.status()); assertEquals(tenant.getUserId(), draft.tenantId());
        assertTrue(notifications.inbox(tenant.getUserId(), 0, false).items().stream().anyMatch(n -> n.getType().equals("CONTRACT_CREATED")));
        assertTrue(draft.documentText().contains("001234567890"));
        assertEquals("AVAILABLE", listings.getMyListings(owner.getUserId()).get(0).getRentalStatus());
        assertEquals(1, leases.getMyContracts(tenant.getEmail()).size());
        try (var book = new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(contractExcel.exportContracts(owner.getEmail())))) {
            assertEquals("0901234567", book.getSheet("HopDong").getRow(1).getCell(1).getStringCellValue());
            assertEquals("DRAFT", book.getSheet("HopDong").getRow(1).getCell(26).getStringCellValue());
        }
    }

    @Autowired com.rental.modules.notification.service.NotificationService notifications;

    @Test void noticesPersistFollowWorkflowAndArePrivateToEachAccount() {
        User owner = user("noticeowner", Role.MEMBER), adminUser = user("noticeadmin", Role.ADMIN), other = user("noticeother", Role.MEMBER);
        CreateListingRequest request = new CreateListingRequest();
        request.setTitle("Phòng có thông báo"); request.setListingType("BOARDING_ROOM"); request.setRentPrice(new BigDecimal("2000000")); request.setAreaSqm(new BigDecimal("20"));
        request.setAddress("TP.HCM"); request.setAreaId(6L); request.setLatitude(10.78); request.setLongitude(106.7); request.setImageUrls(List.of("https://example.com/a.jpg"));
        var created = listings.createListing(owner.getUserId(), request);
        entityManager.flush(); entityManager.clear();
        assertEquals(1, notifications.unreadCount(owner.getUserId()));
        assertEquals("LISTING_PENDING", notifications.inbox(adminUser.getUserId(), 0, false).items().get(0).getType());
        Long noticeId = notifications.inbox(owner.getUserId(), 0, false).items().get(0).getId();
        notifications.markRead(owner.getUserId(), noticeId);
        notifications.markRead(owner.getUserId(), noticeId);
        assertEquals(0, notifications.unreadCount(owner.getUserId()));
        admin.rejectListing(created.getId(), adminUser.getUserId(), "Cần ảnh rõ hơn");
        entityManager.flush(); entityManager.clear();
        var rejected = notifications.inbox(owner.getUserId(), 0, true).items().get(0);
        assertEquals("LISTING_REJECTED", rejected.getType()); assertTrue(rejected.getContent().contains("Cần ảnh rõ hơn"));
        listings.updateListing(created.getId(), owner.getUserId(), request);
        admin.approveListing(created.getId(), adminUser.getUserId());
        entityManager.flush(); entityManager.clear();
        assertTrue(notifications.inbox(owner.getUserId(), 0, false).items().stream().anyMatch(n -> n.getType().equals("LISTING_APPROVED")));
        assertTrue(notifications.inbox(other.getUserId(), 0, false).items().isEmpty());
        notifications.broadcast("Bảo trì", "Hệ thống bảo trì vào cuối tuần.");
        assertEquals("SYSTEM", notifications.inbox(other.getUserId(), 0, false).items().get(0).getType());
        notifications.markAllRead(other.getUserId());
        assertEquals(0, notifications.unreadCount(other.getUserId()));
        assertTrue(notifications.unreadCount(owner.getUserId()) > 0);
        var unreadOwnerNotice = notifications.inbox(owner.getUserId(), 0, true).items().get(0);
        notifications.markRead(owner.getUserId(), unreadOwnerNotice.getId());
        long before = notifications.unreadCount(owner.getUserId());
        notifications.markUnread(owner.getUserId(), unreadOwnerNotice.getId());
        notifications.markUnread(owner.getUserId(), unreadOwnerNotice.getId());
        assertEquals(before + 1, notifications.unreadCount(owner.getUserId()));
        notifications.deleteRead(owner.getUserId());
        assertTrue(notifications.inbox(owner.getUserId(), 0, false).items().stream().noneMatch(n -> n.isRead()));
        notifications.delete(owner.getUserId(), unreadOwnerNotice.getId());
        assertEquals(before, notifications.unreadCount(owner.getUserId()));
        assertFalse(notifications.inbox(other.getUserId(), 0, false).items().isEmpty());
    }

    @Test void sharedRoomSurvivesModerationEditingAndMapVisibility() {
        User owner = user("sharedowner", Role.MEMBER), reviewer = user("sharedadmin", Role.ADMIN);
        CreateListingRequest request = new CreateListingRequest();
        request.setTitle("Tìm người ở ghép"); request.setDescription("Giữ vệ sinh, chia sẻ điện nước");
        request.setListingType("SHARED_ROOM"); request.setRentPrice(new BigDecimal("1500000"));
        request.setAreaSqm(new BigDecimal("30")); request.setAddress("TP.HCM"); request.setAreaId(6L);
        request.setLatitude(10.78); request.setLongitude(106.7);
        request.setImageUrls(List.of("https://example.com/shared.jpg"));
        request.setCurrentOccupants(1); request.setMaxOccupants(3); request.setGenderPreference("FEMALE");
        request.setAllowPets(true); request.setAllowSmoking(false); request.setRoommateRequirements("Giữ vệ sinh");
        Long id = listings.createListing(owner.getUserId(), request).getId();
        entityManager.flush(); entityManager.clear();
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> listings.getPublicListing(id));
        var pending = admin.getPendingListings().stream().filter(l -> l.getId().equals(id)).findFirst().orElseThrow();
        assertEquals(3, pending.getMaxOccupants()); assertEquals("FEMALE", pending.getGenderPreference());
        admin.approveListing(id, reviewer.getUserId());
        entityManager.flush(); entityManager.clear();
        var published = listings.getPublicListing(id);
        assertEquals("SHARED_ROOM", published.getListingType());
        assertEquals(1, published.getCurrentOccupants()); assertTrue(published.getAllowPets());
        assertEquals("Giữ vệ sinh", published.getRoommateRequirements());
        assertEquals(id, listings.searchListingsInBoundingBox(10.7, 106.6, 10.9, 106.8).get(0).getId());
        request.setCurrentOccupants(2);
        listings.updateListing(id, owner.getUserId(), request);
        entityManager.flush(); entityManager.clear();
        assertTrue(listings.getApprovedListings().isEmpty());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> listings.getPublicListing(id));
        admin.approveListing(id, reviewer.getUserId());
        assertEquals(2, listings.getPublicListing(id).getCurrentOccupants());
        listings.updateRentalStatus(id, owner.getUserId(), "HIDDEN");
        assertTrue(listings.searchListingsInBoundingBox(10.7, 106.6, 10.9, 106.8).isEmpty());
    }

    @Autowired com.rental.modules.user.service.UserService userService;

    @Test void personalInterestsPersistClearAndRemainPrivateToEachAccount() {
        User member = user("interestmember", Role.MEMBER), other = user("interestother", Role.MEMBER);
        var request = new com.rental.modules.user.dto.request.UserPreferenceDto(1000000.0, 3000000.0, true, "TP.HCM");
        request.setInterests(List.of("CAT_LOVER", "QUIET", "MUSIC", "CAT_LOVER"));
        userService.updateMyPreferences(member.getEmail(), request);
        entityManager.flush(); entityManager.clear();
        assertEquals(java.util.Set.of("CAT_LOVER", "QUIET", "MUSIC"), new java.util.HashSet<>(userService.getMyPreferences(member.getEmail()).getInterests()));
        assertEquals(1000000.0, userService.getMyPreferences(member.getEmail()).getMinBudget());
        assertTrue(userService.getMyPreferences(other.getEmail()).getInterests().isEmpty());
        assertEquals(3, userService.getMyProfile(member.getEmail()).getInterests().size());
        // Legacy preference updates preserve the selected personal interests.
        request.setInterests(null);
        userService.updateMyPreferences(member.getEmail(), request);
        entityManager.flush(); entityManager.clear();
        assertEquals(3, userService.getMyPreferences(member.getEmail()).getInterests().size());
        // Changing the order or clearing selections must not violate collection constraints.
        request.setInterests(List.of("MUSIC", "CAT_LOVER"));
        userService.updateMyPreferences(member.getEmail(), request);
        entityManager.flush(); entityManager.clear();
        assertEquals(2, userService.getMyPreferences(member.getEmail()).getInterests().size());
        request.setInterests(List.of());
        userService.updateMyPreferences(member.getEmail(), request);
        entityManager.flush(); entityManager.clear();
        assertTrue(userService.getMyProfile(member.getEmail()).getInterests().isEmpty());
    }

    @Autowired UserRepository users;
    @Autowired ListingService listings;
    @Autowired AdminListingService admin;
    @Autowired EntityManager entityManager;
    @Autowired org.springframework.jdbc.core.JdbcTemplate jdbc;
    @Autowired javax.sql.DataSource dataSource;
    @Autowired com.rental.modules.area.service.AreaService areas;
    @Autowired com.rental.modules.property.service.PropertyService properties;
    @Autowired com.rental.modules.favorite.service.ListingFavoriteService favorites;
    @Autowired com.rental.modules.contract.service.ContractService leases;

    @Test void roomContractRequiresCompleteSnapshotAndRejectsOutdatedConsent() {
        User owner = user("roomleaseowner", Role.MEMBER), renter = user("roomleaserenter", Role.MEMBER), reviewer = user("roomleaseadmin", Role.ADMIN);
        CreateListingRequest listing = new CreateListingRequest();
        listing.setTitle("Phòng trọ theo mẫu"); listing.setListingType("BOARDING_ROOM"); listing.setAreaId(6L);
        listing.setAddress("TP.HCM"); listing.setAreaSqm(new BigDecimal("25")); listing.setRentPrice(new BigDecimal("3000000"));
        listing.setLatitude(10.78); listing.setLongitude(106.7); listing.setImageUrls(List.of("https://example.com/room.jpg"));
        Long listingId = listings.createListing(owner.getUserId(), listing).getId();
        admin.approveListing(listingId, reviewer.getUserId());
        var start = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
        var request = new com.rental.modules.contract.dto.request.CreateContractRequest(listingId, renter.getUserId(), start, start.plusMonths(6), new BigDecimal("3000000"), new BigDecimal("1000000"));
        var details = contractDetails(start); request.setDetails(details);
        details.setTenantIdentity(" ");
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> leases.previewContract(owner.getEmail(), request));
        details.setTenantIdentity("Giấy tờ người thuê mẫu");
        var draft = leases.createContract(owner.getEmail(), request);
        assertEquals("ROOM", draft.contractType());
        assertTrue(draft.documentText().contains("HỢP ĐỒNG THUÊ PHÒNG TRỌ"));
        entityManager.flush();
        jdbc.update("update contracts set document_text=null where contract_id=?", draft.id());
        var legacy = leases.getContract(renter.getEmail(), draft.id());
        assertNull(legacy.documentText());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> leases.changeStatus(renter.getEmail(), draft.id(), "ACTIVE", legacy.version()));
        var updated = leases.updateContract(owner.getEmail(), draft.id(), request);
        assertNotNull(updated.documentText());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> leases.changeStatus(renter.getEmail(), draft.id(), "ACTIVE", draft.version()));
        var active = leases.changeStatus(renter.getEmail(), draft.id(), "ACTIVE", updated.version());
        assertNotNull(active.acceptedAt());
        assertEquals("ACTIVE", active.status());
        assertEquals("RENTED", jdbc.queryForObject("select rental_status from listings where listing_id=?", String.class, listingId));
        String agreedDocument = active.documentText();
        owner.setFullName("Tên chủ nhà đã thay đổi"); users.saveAndFlush(owner);
        assertEquals(agreedDocument, leases.getContract(renter.getEmail(), draft.id()).documentText());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> leases.updateContract(owner.getEmail(), draft.id(), request));
    }

    private com.rental.modules.contract.dto.request.ContractDetails contractDetails(java.time.LocalDate start) {
        var details = new com.rental.modules.contract.dto.request.ContractDetails();
        details.setLandlordIdentity("CCCD chủ nhà mẫu"); details.setLandlordAddress("Địa chỉ chủ nhà mẫu");
        details.setTenantIdentity("CCCD người thuê mẫu"); details.setTenantAddress("Địa chỉ người thuê mẫu");
        details.setSigningPlace("TP.HCM"); details.setSigningDate(start.toString()); details.setHandoverDate(start.toString());
        details.setPaymentMethod("Chuyển khoản theo tài khoản được hai bên xác nhận");
        details.setElectricityTerms("Theo hóa đơn điện"); details.setWaterTerms("Theo hóa đơn nước");
        return details;
    }

    @Test void contractLifecycleChecksOwnershipConsentVersionAndListingAvailability() {
        User owner=user("leaseowner",Role.MEMBER), renter=user("renter",Role.MEMBER), outsider=user("outsider",Role.MEMBER), reviewer=user("leaseadmin",Role.ADMIN);
        CreateListingRequest listing=new CreateListingRequest();
        listing.setTitle("Nhà cho thuê"); listing.setListingType("WHOLE_HOUSE"); listing.setAreaId(6L);
        listing.setAddress("TP.HCM"); listing.setAreaSqm(new BigDecimal("50")); listing.setRentPrice(new BigDecimal("5000000"));
        listing.setLatitude(10.78); listing.setLongitude(106.7); listing.setImageUrls(List.of("https://example.com/a.jpg"));
        Long listingId=listings.createListing(owner.getUserId(),listing).getId();
        admin.approveListing(listingId,reviewer.getUserId());
        renter.setPhoneNumber("0901234567");
        users.saveAndFlush(renter);
        assertEquals(renter.getUserId(), leases.findTenant(owner.getEmail(), null, "0901234567", listingId).get("id"));
        assertEquals(renter.getUserId(), leases.findTenant(owner.getEmail(), null, "+84 901-234-567", listingId).get("id"));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,
                () -> leases.findTenant(outsider.getEmail(), null, "0901234567", listingId));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,
                () -> leases.findTenant(owner.getEmail(), null, "abcdefghij", listingId));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,
                () -> leases.findTenant(owner.getEmail(), null, "0909999999", listingId));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,
                () -> leases.findTenant(owner.getEmail(), renter.getEmail(), "0901234567", listingId));
        outsider.setPhoneNumber("+84901234567");
        users.saveAndFlush(outsider);
        assertThrows(org.springframework.web.server.ResponseStatusException.class,
                () -> leases.findTenant(owner.getEmail(), null, "0901234567", listingId));
        outsider.setPhoneNumber(null);
        users.saveAndFlush(outsider);
        var today=java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
        var request=new com.rental.modules.contract.dto.request.CreateContractRequest(listingId,renter.getUserId(),today,today.plusMonths(12),new BigDecimal("5000000"),BigDecimal.ZERO);
        request.setDetails(contractDetails(today));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.createContract(outsider.getEmail(),request));
        assertEquals(renter.getUserId(),leases.findTenant(owner.getEmail(),renter.getEmail(),listingId).get("id"));
        long countBeforePreview = jdbc.queryForObject("select count(*) from contracts", Long.class);
        var preview = leases.previewContract(owner.getEmail(), request);
        assertTrue(preview.get("content").contains("HỢP ĐỒNG THUÊ NHÀ Ở"));
        assertEquals(countBeforePreview, jdbc.queryForObject("select count(*) from contracts", Long.class));
        var draft=leases.createContract(owner.getEmail(),request);
        assertNotNull(draft.documentText());
        assertEquals("HOUSE", draft.contractType());
        assertEquals("DRAFT",draft.status()); assertEquals("LANDLORD",draft.myRole());
        assertEquals("TENANT",leases.getContract(renter.getEmail(),draft.id()).myRole());
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.getContract(outsider.getEmail(),draft.id()));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.createContract(owner.getEmail(),request));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.changeStatus(owner.getEmail(),draft.id(),"ACTIVE",draft.version()));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.updateContract(renter.getEmail(),draft.id(),request));
        request.setMonthlyRent(new BigDecimal("5500000"));
        var edited=leases.updateContract(owner.getEmail(),draft.id(),request);
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.changeStatus(renter.getEmail(),draft.id(),"ACTIVE",draft.version()));
        var active=leases.changeStatus(renter.getEmail(),draft.id(),"ACTIVE",edited.version());
        assertEquals("ACTIVE",active.status()); assertEquals("RENTED",listings.getMyListings(owner.getUserId()).get(0).getRentalStatus());
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->listings.updateRentalStatus(listingId,owner.getUserId(),"AVAILABLE"));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->listings.getPublicListing(listingId));
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.changeStatus(renter.getEmail(),draft.id(),"TERMINATED",active.version()));
        var ended=leases.changeStatus(owner.getEmail(),draft.id(),"TERMINATED",active.version());
        assertEquals("TERMINATED",ended.status()); assertEquals("HIDDEN",listings.getMyListings(owner.getUserId()).get(0).getRentalStatus());
        listings.updateRentalStatus(listingId,owner.getUserId(),"AVAILABLE");
        var second=leases.createContract(owner.getEmail(),request);
        var cancelled=leases.changeStatus(renter.getEmail(),second.id(),"CANCELLED",second.version());
        assertEquals("CANCELLED",cancelled.status());
        var third=leases.createContract(owner.getEmail(),request);
        leases.changeStatus(renter.getEmail(),third.id(),"ACTIVE",third.version());
        jdbc.update("UPDATE contracts SET start_date=?, end_date=? WHERE contract_id=?",today.minusDays(5),today.minusDays(1),third.id());
        entityManager.clear();
        assertEquals("EXPIRED",leases.getContract(owner.getEmail(),third.id()).status());
        assertEquals("HIDDEN",listings.getMyListings(owner.getUserId()).get(0).getRentalStatus());
        var ownerTypes = notifications.inbox(owner.getUserId(), 0, false).items().stream().map(n -> n.getType()).toList();
        var tenantTypes = notifications.inbox(renter.getUserId(), 0, false).items().stream().map(n -> n.getType()).toList();
        assertTrue(ownerTypes.containsAll(List.of("CONTRACT_ACTIVE", "CONTRACT_CANCELLED", "CONTRACT_EXPIRED")));
        assertTrue(tenantTypes.containsAll(List.of("CONTRACT_CREATED", "CONTRACT_UPDATED", "CONTRACT_TERMINATED", "CONTRACT_EXPIRED")));
        long expiredBefore = notifications.inbox(owner.getUserId(), 0, false).items().stream().filter(n -> n.getType().equals("CONTRACT_EXPIRED")).count();
        leases.getContract(owner.getEmail(), third.id());
        assertEquals(expiredBefore, notifications.inbox(owner.getUserId(), 0, false).items().stream().filter(n -> n.getType().equals("CONTRACT_EXPIRED")).count());
        request.setEndDate(request.getStartDate());
        assertThrows(org.springframework.web.server.ResponseStatusException.class,()->leases.createContract(owner.getEmail(),request));
    }

    @Test void areaNameRepairRestoresVietnameseAndPreservesCustomNamesAndIds() {
        int areaCount = jdbc.queryForObject("SELECT count(*) FROM administrative_areas", Integer.class);
        jdbc.update("UPDATE administrative_areas SET area_name = ? WHERE area_id = 1", "Th??nh ph??? H??? Ch?? Minh");
        jdbc.update("UPDATE administrative_areas SET area_name = ? WHERE area_id = 6", "Ph?????ng B???n Ngh??");
        jdbc.update("UPDATE administrative_areas SET area_name = ? WHERE area_id = 2", "Tên khu vực tùy chỉnh");
        var repair = new org.springframework.jdbc.datasource.init.ResourceDatabasePopulator(
                new ClassPathResource("db/migration/V9__repair_seed_area_names_utf8.sql"));
        repair.execute(dataSource);
        assertEquals("Thành phố Hồ Chí Minh", jdbc.queryForObject("SELECT area_name FROM administrative_areas WHERE area_id=1", String.class));
        assertEquals("Phường Bến Nghé", jdbc.queryForObject("SELECT area_name FROM administrative_areas WHERE area_id=6", String.class));
        assertEquals("Tên khu vực tùy chỉnh", jdbc.queryForObject("SELECT area_name FROM administrative_areas WHERE area_id=2", String.class));
        assertEquals(2L, jdbc.queryForObject("SELECT parent_id FROM administrative_areas WHERE area_id=6", Long.class));
        assertEquals(areaCount, jdbc.queryForObject("SELECT count(*) FROM administrative_areas", Integer.class));
        repair.execute(dataSource);
        assertEquals("Tên khu vực tùy chỉnh", jdbc.queryForObject("SELECT area_name FROM administrative_areas WHERE area_id=2", String.class));
    }

    @Test void postMergerAreasAreCompleteAndSupportTwoLevelAddresses() {
        var units = areas.getWardsByProvince(1L);
        assertEquals(168, units.size());
        assertEquals(113L, units.stream().filter(w -> "WARD".equals(w.getType())).count());
        assertEquals(54L, units.stream().filter(w -> "COMMUNE".equals(w.getType())).count());
        assertEquals(1L, units.stream().filter(w -> "SPECIAL".equals(w.getType())).count());
        assertTrue(units.stream().allMatch(w -> w.getProvinceId().equals(1L) && w.getDistrictId() == null));
        assertEquals(168L, units.stream().map(w -> w.getCode()).distinct().count());
        assertTrue(units.stream().anyMatch(w -> w.getName().equals("Phường Sài Gòn")));
        assertTrue(units.stream().anyMatch(w -> w.getName().equals("Phường Dĩ An")));
        assertTrue(units.stream().anyMatch(w -> w.getName().equals("Phường Vũng Tàu")));
        assertEquals("Phường Bến Nghé", areas.getWardsByDistrict(2L).stream()
                .filter(w -> w.getId().equals(6L)).findFirst().orElseThrow().getName());
        new org.springframework.jdbc.datasource.init.ResourceDatabasePopulator(new ClassPathResource(
                "db/migration/V10__hcm_post_merger_commune_level_areas.sql")).execute(dataSource);
        assertEquals(168, areas.getWardsByProvince(1L).size());

        User owner = user("newareas", Role.MEMBER);
        for (String type : List.of("WARD", "COMMUNE", "SPECIAL")) {
            var unit = units.stream().filter(w -> type.equals(w.getType())).findFirst().orElseThrow();
            CreateListingRequest request = new CreateListingRequest();
            request.setTitle("Tin ở " + unit.getName()); request.setListingType("BOARDING_ROOM");
            request.setRentPrice(new BigDecimal("3000000")); request.setAreaSqm(new BigDecimal("30"));
            request.setAddress(unit.getName() + ", TP.HCM"); request.setAreaId(unit.getId());
            request.setLatitude(10.78); request.setLongitude(106.7);
            request.setImageUrls(List.of("https://example.com/room.jpg"));
            assertNotNull(listings.createListing(owner.getUserId(), request).getId());
            var property = new com.rental.modules.property.dto.request.PropertyRequest(
                    "Khu trọ", "", "Địa chỉ", 1L, null, unit.getId(), "BOARDING_HOUSE",
                    BigDecimal.ZERO, BigDecimal.ZERO, List.of());
            var result = properties.createProperty(owner.getEmail(), property);
            assertNull(result.getDistrictId());
            assertEquals(unit.getId(), result.getWardId());
            property.setProvinceId(2L);
            assertThrows(org.springframework.web.server.ResponseStatusException.class,
                    () -> properties.createProperty(owner.getEmail(), property));
        }
        entityManager.flush();
    }

    private User user(String name, Role role) {
        User u = new User();
        u.setFullName(name); u.setEmail(name + "@example.com"); u.setRole(role);
        u.setStatus(UserStatus.ACTIVE); u.setIsVerified(true);
        return users.saveAndFlush(u);
    }

    @Test void migrationsImagesModerationAndSpatialVisibilityWorkOnRealPostgis() {
        User owner = user("owner", Role.MEMBER);
        User reviewer = user("reviewer", Role.ADMIN);
        CreateListingRequest request = new CreateListingRequest();
        request.setTitle("Phòng trọ kiểm thử"); request.setListingType("BOARDING_ROOM");
        request.setRentPrice(new BigDecimal("3000000")); request.setAreaSqm(new BigDecimal("30"));
        request.setAddress("TP.HCM"); request.setAreaId(6L);
        request.setLatitude(10.78); request.setLongitude(106.7);
        request.setImageUrls(List.of("https://example.com/room.jpg"));
        Long id = listings.createListing(owner.getUserId(), request).getId();
        entityManager.flush(); entityManager.clear();
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> listings.getPublicListing(id));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> favorites.save(owner.getUserId(), id));
        assertEquals(List.of("https://example.com/room.jpg"), listings.getMyListings(owner.getUserId()).get(0).getImageUrls());
        assertTrue(listings.searchListingsInBoundingBox(10.7, 106.6, 10.9, 106.8).isEmpty());
        admin.approveListing(id, reviewer.getUserId());
        entityManager.flush(); entityManager.clear();
        assertEquals(owner.getFullName(), listings.getPublicListing(id).getOwnerName());
        assertEquals(request.getImageUrls(), listings.getPublicListing(id).getImageUrls());
        favorites.save(owner.getUserId(), id);
        favorites.save(owner.getUserId(), id);
        assertTrue(favorites.isSaved(owner.getUserId(), id));
        assertFalse(favorites.isSaved(reviewer.getUserId(), id));
        assertEquals(1, favorites.getSaved(owner.getUserId()).size());
        favorites.remove(reviewer.getUserId(), id);
        assertTrue(favorites.isSaved(owner.getUserId(), id));
        assertEquals(id, listings.searchListingsInBoundingBox(10.7, 106.6, 10.9, 106.8).get(0).getId());
        assertTrue(listings.searchListingsInBoundingBox(11, 107, 12, 108).isEmpty());
        listings.updateListing(id, owner.getUserId(), request);
        entityManager.flush(); entityManager.clear();
        assertTrue(listings.getApprovedListings().isEmpty());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> listings.getPublicListing(id));
        assertTrue(favorites.getSaved(owner.getUserId()).isEmpty());
        assertEquals(1, listings.getMyListings(owner.getUserId()).get(0).getImageUrls().size());
        admin.approveListing(id, reviewer.getUserId());
        listings.updateRentalStatus(id, owner.getUserId(), "HIDDEN");
        entityManager.flush(); entityManager.clear();
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> listings.getPublicListing(id));
        assertTrue(favorites.getSaved(owner.getUserId()).isEmpty());
        assertTrue(listings.searchListingsInBoundingBox(10.7, 106.6, 10.9, 106.8).isEmpty());
        listings.updateRentalStatus(id, owner.getUserId(), "AVAILABLE");
        listings.deleteListing(id, owner.getUserId());
        entityManager.flush(); entityManager.clear();
        assertTrue(listings.getMyListings(owner.getUserId()).isEmpty());
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> listings.getPublicListing(id));
        favorites.remove(owner.getUserId(), id);
        assertFalse(favorites.isSaved(owner.getUserId(), id));
        assertTrue(listings.getApprovedListings().isEmpty());
    }
}
