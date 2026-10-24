package com.rental.modules.user;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@EnabledIfEnvironmentVariable(named = "RENTAL_POSTGIS_TESTS", matches = "true")
class MemberRoleMigrationTest {
    @Test
    void existingUsersBecomeMembersWithoutLosingRelatedData() throws Exception {
        var yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yml"));
        var configuration = yaml.getObject();
        String url = configuration.getProperty("spring.datasource.url");
        if (!url.matches("jdbc:postgresql://(127\\.0\\.0\\.1|localhost):[0-9]+/.*")) {
            throw new IllegalStateException("Migration tests require a local development database");
        }
        String schema = "member_roles_" + UUID.randomUUID().toString().replace("-", "");
        String testUrl = url + (url.contains("?") ? "&" : "?") + "currentSchema=" + schema + ",public";
        String username = configuration.getProperty("spring.datasource.username");
        String password = configuration.getProperty("spring.datasource.password");
        try (var connection = DriverManager.getConnection(url, username, password);
             var statement = connection.createStatement()) {
            statement.execute("CREATE SCHEMA " + schema);
            try {
                Flyway.configure().dataSource(testUrl, username, password)
                    .schemas(schema).defaultSchema(schema).target("16").load().migrate();
                try (var testConnection = DriverManager.getConnection(testUrl, username, password);
                     var testStatement = testConnection.createStatement()) {
                    testStatement.execute("INSERT INTO users (user_id, full_name, email, role) VALUES "
                        + "(101, 'Tenant', 'tenant@example.com', 'USER'), "
                        + "(102, 'Owner', 'owner@example.com', 'OWNER'), "
                        + "(103, 'Admin', 'admin@example.com', 'ADMIN')");
                    testStatement.execute("INSERT INTO user_preferences (user_id) VALUES (101), (102)");
                }
                var flyway = Flyway.configure().dataSource(testUrl, username, password)
                    .schemas(schema).defaultSchema(schema).load();
                assertEquals(2, flyway.migrate().migrationsExecuted);
                flyway.validate();
                assertEquals(0, flyway.migrate().migrationsExecuted);
                try (var testConnection = DriverManager.getConnection(testUrl, username, password);
                     var testStatement = testConnection.createStatement()) {
                    try (var rows = testStatement.executeQuery("SELECT user_id, role FROM users ORDER BY user_id")) {
                        assertTrue(rows.next()); assertEquals(101, rows.getLong(1)); assertEquals("MEMBER", rows.getString(2));
                        assertTrue(rows.next()); assertEquals(102, rows.getLong(1)); assertEquals("MEMBER", rows.getString(2));
                        assertTrue(rows.next()); assertEquals(103, rows.getLong(1)); assertEquals("ADMIN", rows.getString(2));
                        assertFalse(rows.next());
                    }
                    try (var rows = testStatement.executeQuery("SELECT count(*) FROM user_preferences p JOIN users u USING (user_id) WHERE u.role = 'MEMBER'")) {
                        assertTrue(rows.next()); assertEquals(2, rows.getInt(1));
                    }
                    assertThrows(SQLException.class, () -> testStatement.execute("UPDATE users SET role = 'USER' WHERE user_id = 101"));
                    assertThrows(SQLException.class, () -> testStatement.execute("UPDATE users SET role = 'OWNER' WHERE user_id = 102"));
                }
            } finally {
                if (!schema.matches("member_roles_[a-f0-9]{32}")) throw new IllegalStateException("Unexpected test schema");
                statement.execute("DROP SCHEMA " + schema + " CASCADE");
            }
        }
    }
}
