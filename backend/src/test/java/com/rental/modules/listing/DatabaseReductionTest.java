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
import java.util.TreeMap;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@EnabledIfEnvironmentVariable(named = "RENTAL_POSTGIS_TESTS", matches = "true")
class DatabaseReductionTest {
    @Test
    void reductionProtectsOccupiedTablesAndPreservesTheRemainingSchema() throws Exception {
        var yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yml"));
        var config = yaml.getObject();
        String url = config.getProperty("spring.datasource.url");
        if (!url.matches("jdbc:postgresql://(127\\.0\\.0\\.1|localhost):[0-9]+/.*")) {
            throw new IllegalStateException("Use a local test database");
        }
        String legacy;
        try (var input = new ClassPathResource("database-before-vietnamese.sql").getInputStream()) {
            legacy = new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }
        String rename = Files.readString(Path.of("scripts/doi_ten_database_sang_tieng_viet.sql"));
        String reduce = Files.readString(Path.of("scripts/rut_gon_database_con_23_bang.sql"));
        String schema = "reduction_" + UUID.randomUUID().toString().replace("-", "");
        String fresh = schema + "_fresh";
        String[][] occupied = {
            {"noi_dung_he_thong_cu", "INSERT INTO noi_dung_he_thong_cu(ma_trang_noi_dung) VALUES ('test')"},
            {"phien_dang_nhap_qr_cu", "INSERT INTO phien_dang_nhap_qr_cu(ma_phien) VALUES ('00000000-0000-0000-0000-000000000001')"},
            {"danh_muc_noi_that", "INSERT INTO danh_muc_noi_that(ten_noi_that) VALUES ('Test')"},
            {"noi_that_cua_tin_dang", "INSERT INTO noi_that_cua_tin_dang(ma_tin_dang,ma_noi_that) VALUES (1,1)"},
            {"theo_doi_tin_dang", "INSERT INTO theo_doi_tin_dang(ma_nguoi_dung,ma_tin_dang) VALUES (1,1)"},
            {"tin_nhan_lien_he", "INSERT INTO tin_nhan_lien_he(chu_de) VALUES ('Test')"}
        };
        try (var connection = DriverManager.getConnection(url, config.getProperty("spring.datasource.username"), config.getProperty("spring.datasource.password"));
             var sql = connection.createStatement()) {
            sql.execute("CREATE SCHEMA " + schema);
            sql.execute("CREATE SCHEMA " + fresh);
            try {
                sql.execute("SET search_path TO " + schema + ", public");
                sql.execute(legacy);
                sql.execute(rename);
                sql.execute("INSERT INTO nguoi_dung(ho_va_ten,dia_chi_thu_dien_tu,vai_tro) VALUES ('Test','reduction@example.com','MEMBER')");
                sql.execute("INSERT INTO tin_cho_thue(ma_chu_tin,ma_khu_vuc,tieu_de,loai_tin_dang,gia_cho_thue,toa_do_vi_tri) VALUES (1,1,'Test','WHOLE_HOUSE',3000000,ST_SetSRID(ST_MakePoint(106.7,10.78),4326))");
                var before = snapshot(connection);
                assertEquals(29, before.size());

                for (String[] item : occupied) {
                    if (item[0].equals("noi_that_cua_tin_dang")) {
                        sql.execute("INSERT INTO danh_muc_noi_that(ma_noi_that,ten_noi_that) VALUES (1,'Parent')");
                    }
                    sql.execute(item[1]);
                    assertThrows(SQLException.class, () -> sql.execute(reduce));
                    sql.execute("ROLLBACK");
                    assertEquals(29, snapshot(connection).size());
                    try (var rows = sql.executeQuery("SELECT count(*) FROM " + item[0])) {
                        rows.next();
                        assertEquals(1, rows.getInt(1));
                    }
                    sql.execute("DELETE FROM " + item[0]);
                    if (item[0].equals("noi_that_cua_tin_dang")) sql.execute("DELETE FROM danh_muc_noi_that");
                }

                sql.execute("CREATE TABLE custom_dependency(id BIGINT REFERENCES noi_dung_he_thong_cu(ma_noi_dung))");
                assertThrows(SQLException.class, () -> sql.execute(reduce));
                sql.execute("ROLLBACK");
                assertEquals(30, snapshot(connection).size());
                sql.execute("DROP TABLE custom_dependency");

                sql.execute(reduce);
                var after = snapshot(connection);
                assertEquals(23, after.size());
                for (String[] item : occupied) before.remove(item[0]);
                assertEquals(before, after);
                var structure = columns(connection);
                sql.execute(reduce);
                assertEquals(after, snapshot(connection));

                sql.execute("SET search_path TO " + fresh + ", public");
                sql.execute(Files.readString(Path.of("database.sql")));
                assertEquals(23, snapshot(connection).size());
                assertEquals(structure, columns(connection));
            } finally {
                sql.execute("ROLLBACK");
                sql.execute("DROP SCHEMA " + schema + " CASCADE");
                sql.execute("DROP SCHEMA " + fresh + " CASCADE");
            }
        }
    }

    private Map<String, String> snapshot(Connection connection) throws SQLException {
        Map<String, String> result = new TreeMap<>();
        try (var sql = connection.createStatement();
             var rows = sql.executeQuery("SELECT tablename FROM pg_tables WHERE schemaname=current_schema() ORDER BY tablename")) {
            while (rows.next()) result.put(rows.getString(1), "");
        }
        for (String table : result.keySet()) {
            try (var sql = connection.createStatement();
                 var rows = sql.executeQuery("SELECT count(*) || ':' || coalesce(md5(string_agg(md5(t::text),'|' ORDER BY md5(t::text))),'') FROM " + table + " t")) {
                rows.next();
                result.put(table, rows.getString(1));
            }
        }
        return result;
    }

    private Map<String, String> columns(Connection connection) throws SQLException {
        Map<String, String> result = new TreeMap<>();
        try (var sql = connection.createStatement();
             var rows = sql.executeQuery("SELECT table_name,column_name,data_type,udt_name,is_nullable FROM information_schema.columns WHERE table_schema=current_schema()")) {
            while (rows.next()) result.put(rows.getString(1) + "." + rows.getString(2), rows.getString(3) + ":" + rows.getString(4) + ":" + rows.getString(5));
        }
        return result;
    }
}
