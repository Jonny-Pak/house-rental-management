package com.rental.modules.listing;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;

@EnabledIfEnvironmentVariable(named = "RENTAL_POSTGIS_TESTS", matches = "true")
class DatabaseSqlTest {
    @Test void standaloneSqlCreatesSchemaAndProtectsExistingData() throws Exception {
        var yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yml"));
        var config = yaml.getObject();
        String url = config.getProperty("spring.datasource.url");
        if (!url.matches("jdbc:postgresql://(127\\.0\\.0\\.1|localhost):[0-9]+/.*")) throw new IllegalStateException("Use a local test database");
        String schema = "standalone_sql_" + UUID.randomUUID().toString().replace("-", "");
        try (var connection = DriverManager.getConnection(url, config.getProperty("spring.datasource.username"), config.getProperty("spring.datasource.password"));
             var sql = connection.createStatement()) {
            sql.execute("CREATE SCHEMA " + schema);
            try {
                sql.execute("SET search_path TO " + schema + ", public");
                String script = Files.readString(Path.of("database.sql"));
                sql.execute(script);
                try (var query = connection.prepareStatement("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ? AND table_type = 'BASE TABLE'")) {
                    query.setString(1, schema);
                    try (var rows = query.executeQuery()) { rows.next(); assertEquals(23, rows.getInt(1)); }
                }
                try (var rows = sql.executeQuery("SELECT COUNT(*) FROM goi_dich_vu")) { rows.next(); assertEquals(3, rows.getInt(1)); }
                sql.execute("INSERT INTO nguoi_dung(ho_va_ten,dia_chi_thu_dien_tu,vai_tro) VALUES ('Member','member@example.com','MEMBER'),('Admin','admin@example.com','ADMIN')");
                assertThrows(SQLException.class, () -> sql.execute("INSERT INTO nguoi_dung(ho_va_ten,dia_chi_thu_dien_tu,vai_tro) VALUES ('Invalid','invalid@example.com','USER')"));
                assertThrows(SQLException.class, () -> sql.execute(script));
                sql.execute("ROLLBACK");
                try (var rows = sql.executeQuery("SELECT COUNT(*) FROM nguoi_dung")) { rows.next(); assertEquals(2, rows.getInt(1)); }
            } finally {
                sql.execute("ROLLBACK");
                sql.execute("DROP SCHEMA " + schema + " CASCADE");
            }
        }
    }
}
