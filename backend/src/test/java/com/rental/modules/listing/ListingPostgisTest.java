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
@Import({ListingService.class, AdminListingService.class, com.rental.modules.area.service.AreaService.class,
        com.rental.modules.property.service.PropertyService.class,
        com.rental.modules.favorite.service.ListingFavoriteService.class,
        com.rental.modules.contract.service.ContractService.class, com.rental.modules.contract.service.ContractDocumentService.class})
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
        User owner = user("roomleaseowner", Role.OWNER), renter = user("roomleaserenter", Role.USER), reviewer = user("roomleaseadmin", Role.ADMIN);
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
        User owner=user("leaseowner",Role.OWNER), renter=user("renter",Role.USER), outsider=user("outsider",Role.USER), reviewer=user("leaseadmin",Role.ADMIN);
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

        User owner = user("newareas", Role.OWNER);
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
        User owner = user("owner", Role.USER);
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
