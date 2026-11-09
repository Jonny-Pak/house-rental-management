package com.rental.modules.listing;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Map;
import java.util.Properties;
import java.util.TreeMap;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@EnabledIfEnvironmentVariable(named = "RENTAL_POSTGIS_TESTS", matches = "true")
class VietnameseDatabaseRenameTest {
    @Test
    void renamePreservesAllRowsRelationsAndSequencesAndCanBeReversed() throws Exception {
        var yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yml"));
        var config = yaml.getObject();
        String url = config.getProperty("spring.datasource.url");
        if (!url.matches("jdbc:postgresql://(127\\.0\\.0\\.1|localhost):[0-9]+/.*")) {
            throw new IllegalStateException("Use a local test database");
        }
        Properties tableNames = new Properties();
        try (var input = new ClassPathResource("database-vietnamese-tables.properties").getInputStream()) {
            tableNames.load(input);
        }
        String legacy;
        try (var input = new ClassPathResource("database-before-vietnamese.sql").getInputStream()) {
            legacy = new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }
        String rename = Files.readString(Path.of("scripts/doi_ten_database_sang_tieng_viet.sql"));
        String reverse = Files.readString(Path.of("scripts/khoi_phuc_ten_database_tieng_anh.sql"));
        String schema = "vietnamese_rename_" + UUID.randomUUID().toString().replace("-", "");
        try (var connection = DriverManager.getConnection(url, config.getProperty("spring.datasource.username"), config.getProperty("spring.datasource.password"));
             var sql = connection.createStatement()) {
            sql.execute("CREATE SCHEMA " + schema);
            try {
                sql.execute("SET search_path TO " + schema + ",public");
                sql.execute(legacy);
                sql.execute("INSERT INTO users(full_name,email,role) VALUES ('Owner','owner@example.com','MEMBER'),('Tenant','tenant@example.com','MEMBER')");
                sql.execute("INSERT INTO listings(owner_id,area_id,title,listing_type,rent_price,location) VALUES (1,1,'Migration test','WHOLE_HOUSE',3000000,ST_SetSRID(ST_MakePoint(106.7,10.78),4326))");
                sql.execute("INSERT INTO contracts(listing_id,landlord_id,tenant_id,start_date,end_date,monthly_rent) VALUES (1,1,2,'2026-11-01','2027-11-01',3000000)");
                var before = snapshot(connection, tableNames, false);
                assertEquals(43, foreignKeys(connection));

                sql.execute(rename);
                assertEquals(before, snapshot(connection, tableNames, true));
                assertEquals(43, foreignKeys(connection));
                try (var rows = sql.executeQuery("SELECT count(*) FROM information_schema.columns WHERE table_schema=current_schema()")) {
                    rows.next();
                    assertEquals(246, rows.getInt(1));
                }
                assertThrows(SQLException.class, () -> sql.execute(rename));
                sql.execute("ROLLBACK");
                assertEquals(before, snapshot(connection, tableNames, true));

                sql.execute(reverse);
                assertEquals(before, snapshot(connection, tableNames, false));
                sql.execute(rename);
                try (var rows = sql.executeQuery("INSERT INTO nguoi_dung(ho_va_ten,dia_chi_thu_dien_tu,vai_tro) VALUES ('New member','new@example.com','MEMBER') RETURNING ma_nguoi_dung")) {
                    assertTrue(rows.next());
                    assertEquals(3, rows.getLong(1));
                }
                assertThrows(SQLException.class, () -> sql.execute("INSERT INTO hop_dong_thue(ma_tin_dang,ma_ben_cho_thue,ma_ben_thue,ngay_bat_dau,ngay_ket_thuc,tien_thue_moi_thang) VALUES (999999,1,2,'2026-11-01','2027-11-01',1)"));
            } finally {
                sql.execute("ROLLBACK");
                sql.execute("DROP SCHEMA " + schema + " CASCADE");
            }
        }
    }

    private Map<String, String> snapshot(Connection connection, Properties names, boolean vietnamese) throws SQLException {
        Map<String, String> result = new TreeMap<>();
        try (var sql = connection.createStatement()) {
            for (String oldName : names.stringPropertyNames()) {
                String table = vietnamese ? names.getProperty(oldName) : oldName;
                if (!table.matches("[a-z_]+")) throw new IllegalStateException("Invalid test table");
                try (var rows = sql.executeQuery("SELECT count(*) || ':' || coalesce(md5(string_agg(md5(t::text),'|' ORDER BY md5(t::text))),'') FROM " + table + " t")) {
                    rows.next();
                    result.put(oldName, rows.getString(1));
                }
            }
        }
        return result;
    }

    private int foreignKeys(Connection connection) throws SQLException {
        try (var sql = connection.createStatement();
             var rows = sql.executeQuery("SELECT count(*) FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname=current_schema() AND c.contype='f'")) {
            rows.next();
            return rows.getInt(1);
        }
    }
}
