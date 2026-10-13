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
        com.rental.modules.favorite.service.ListingFavoriteService.class})
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
