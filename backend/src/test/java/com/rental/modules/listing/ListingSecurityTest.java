package com.rental.modules.listing;

import com.rental.core.security.*;
import com.rental.modules.admin.controller.AdminListingController;
import com.rental.modules.admin.service.AdminListingService;
import com.rental.modules.listing.controller.ListingController;
import com.rental.modules.listing.service.ListingService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest({com.rental.modules.subscription.controller.AdminPackageController.class, com.rental.modules.payment.controller.PaymentController.class, com.rental.modules.incident.controller.IncidentController.class, com.rental.modules.incident.controller.AdminIncidentController.class, com.rental.modules.user.controller.PasswordController.class, com.rental.modules.report.ReportController.class, com.rental.modules.content.controller.AdminContentController.class, com.rental.modules.content.controller.ContentController.class, com.rental.modules.admin.controller.AdminAreaController.class, com.rental.modules.admin.controller.AdminUserController.class, com.rental.modules.notification.controller.NotificationController.class, ListingController.class, AdminListingController.class,
        com.rental.modules.listing.controller.ListingExcelController.class,
        com.rental.modules.contract.controller.ContractExcelController.class,
        com.rental.modules.favorite.controller.ListingFavoriteController.class,
        com.rental.modules.contract.controller.ContractController.class})
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class ListingSecurityTest {
    @MockBean com.rental.modules.subscription.service.AdminPackageService adminPackages;
    @MockBean com.rental.modules.payment.service.PaymentService payments;
    @Test void packageManagementIsAdminOnlyAndValidatesPricesQuotasAndVersions() throws Exception {
        String body = "{\"packageName\":\"Gói mới\",\"price\":50000,\"standardPostQuota\":10,\"vipPostQuota\":2,\"refreshQuota\":3,\"description\":\"Mô tả\",\"active\":true,\"version\":0}";
        mvc.perform(get("/api/v1/admin/memberships")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/memberships").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/memberships").header("Authorization", "Bearer owner").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(put("/api/v1/admin/memberships/1").header("Authorization", "Bearer owner").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(delete("/api/v1/admin/memberships/1").header("Authorization", "Bearer owner").param("version", "0")).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/memberships").header("Authorization", "Bearer admin").contentType("application/json").content(body)).andExpect(status().isCreated());
        mvc.perform(put("/api/v1/admin/memberships/1").header("Authorization", "Bearer admin").contentType("application/json").content(body)).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/memberships/1/status").header("Authorization", "Bearer admin").contentType("application/json").content("{\"active\":false,\"version\":0}")).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/admin/memberships/1").header("Authorization", "Bearer admin").param("version", "0")).andExpect(status().isOk());
        mvc.perform(post("/api/v1/admin/memberships").header("Authorization", "Bearer admin").contentType("application/json").content(body.replace("50000", "-1"))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/memberships").header("Authorization", "Bearer admin").contentType("application/json").content(body.replace("50000", "1.5"))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/memberships").header("Authorization", "Bearer admin").contentType("application/json").content(body.replace("\"standardPostQuota\":10", "\"standardPostQuota\":32768"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/memberships/1/status").header("Authorization", "Bearer admin").contentType("application/json").content("{\"active\":false}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/payments/create").header("Authorization", "Bearer owner").contentType("application/json").content("{\"packageId\":65537}")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/payments/vnpay-return").param("vnp_SecureHash", "invalid")).andExpect(status().is3xxRedirection());
        verify(payments).processVnPayReturn(anyMap());
    }

    @MockBean com.rental.modules.incident.service.IncidentService incidents;
    @Test void incidentsRequireLoginOwnerScopeAndAdminProcessingPermission() throws Exception {
        String create = "{\"requestKey\":\"request-1\",\"title\":\"Lỗi ứng dụng\",\"category\":\"TECHNICAL\",\"description\":\"Không mở được bản đồ\",\"reporterId\":999}";
        mvc.perform(post("/api/v1/incidents").contentType("application/json").content(create)).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/incidents/me")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/incidents/1")).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/incidents").header("Authorization", "Bearer owner").contentType("application/json").content(create)).andExpect(status().isCreated());
        verify(incidents).create(eq(1L), any());
        mvc.perform(get("/api/v1/incidents/me").header("Authorization", "Bearer owner").param("reporterId", "999")).andExpect(status().isOk());
        verify(incidents).search(eq(1L), eq(""), isNull(), isNull(), eq(0));
        mvc.perform(get("/api/v1/incidents/9").header("Authorization", "Bearer owner")).andExpect(status().isOk());
        verify(incidents).detail(9L, 1L);
        String update = "{\"status\":\"RESOLVED\",\"message\":\"Đã xử lý\",\"version\":0}";
        mvc.perform(get("/api/v1/admin/incidents").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/incidents/9").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/admin/incidents/9").header("Authorization", "Bearer owner").contentType("application/json").content(update)).andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/admin/incidents/9").header("Authorization", "Bearer admin").contentType("application/json").content(update)).andExpect(status().isOk());
        verify(incidents).update(eq(9L), eq(2L), any());
        mvc.perform(post("/api/v1/incidents").header("Authorization", "Bearer owner").contentType("application/json").content(create.replace("Lỗi ứng dụng", " "))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/incidents").header("Authorization", "Bearer owner").contentType("application/json").content(create.replace("TECHNICAL", "BAD"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/incidents/9").header("Authorization", "Bearer admin").contentType("application/json").content(update.replace("Đã xử lý", " "))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/incidents/9").header("Authorization", "Bearer admin").contentType("application/json").content(update.replace("RESOLVED", "OPEN"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/incidents/9").header("Authorization", "Bearer admin").contentType("application/json").content(update.replace("0", "-1"))).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/admin/incidents").header("Authorization", "Bearer admin").param("page", "bad")).andExpect(status().isBadRequest());
    }

    @MockBean com.rental.modules.user.service.PasswordService passwords;
    @Test void passwordResetIsPublicAndChangeUsesAuthenticatedIdentity() throws Exception {
        mvc.perform(post("/api/v1/auth/forgot-password").contentType("application/json").content("{\"email\":\"member@example.com\"}")).andExpect(status().isOk());
        mvc.perform(post("/api/v1/auth/reset-password").contentType("application/json").content("{\"email\":\"member@example.com\",\"otp\":\"123456\",\"newPassword\":\"NewPassword123\"}")).andExpect(status().isOk());
        mvc.perform(post("/api/v1/auth/reset-password").contentType("application/json").content("{\"email\":\"member@example.com\",\"otp\":\"12\",\"newPassword\":\"short\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/auth/forgot-password").contentType("application/json").content("{\"email\":\"invalid\"}")).andExpect(status().isBadRequest());
        String body = "{\"currentPassword\":\"OldPassword123\",\"newPassword\":\"NewPassword123\",\"email\":\"victim@example.com\"}";
        mvc.perform(post("/api/v1/users/me/change-password").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/users/me/change-password").header("Authorization", "Bearer owner").contentType("application/json").content(body)).andExpect(status().isOk());
        verify(passwords).change(eq("owner"), any());
        mvc.perform(post("/api/v1/users/me/change-password").header("Authorization", "Bearer admin").contentType("application/json").content(body)).andExpect(status().isOk());
        verify(passwords).change(eq("admin"), any());
    }

    @MockBean com.rental.modules.report.ReportService reports;
    @MockBean com.rental.modules.report.ReportExcel reportExcel;

    @Test void reportsAndExcelRequireAdmin() throws Exception {
        for (String path : java.util.List.of("/api/v1/admin/reports", "/api/v1/admin/reports/export")) {
            mvc.perform(get(path).param("from", "2026-01-01").param("to", "2026-01-31")).andExpect(status().isForbidden());
            mvc.perform(get(path).header("Authorization", "Bearer owner").param("from", "2026-01-01").param("to", "2026-01-31")).andExpect(status().isForbidden());
        }
        verifyNoInteractions(reports, reportExcel);
        mvc.perform(get("/api/v1/admin/reports").header("Authorization", "Bearer admin").param("from", "2026-01-01").param("to", "2026-01-31")).andExpect(status().isOk());
        verify(reports).report(java.time.LocalDate.of(2026, 1, 1), java.time.LocalDate.of(2026, 1, 31));
        when(reportExcel.write(any())).thenReturn(new byte[]{1,2});
        mvc.perform(get("/api/v1/admin/reports/export").header("Authorization", "Bearer admin").param("from", "2026-01-01").param("to", "2026-01-31"))
            .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
            .andExpect(content().contentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
        mvc.perform(get("/api/v1/admin/reports").header("Authorization", "Bearer admin").param("from", "bad").param("to", "2026-01-31")).andExpect(status().isBadRequest());
    }

    @MockBean com.rental.modules.content.service.SystemContentService contentService;

    @Test void contentReadersOnlyReceivePublishedFieldsAndOnlyAdminsCanEdit() throws Exception {
        var published = new com.rental.modules.content.dto.PublishedContentResponse("about", "Public title", "Public body", java.time.LocalDateTime.now());
        when(contentService.published("about")).thenReturn(published);
        mvc.perform(get("/api/v1/content/about")).andExpect(status().isOk())
            .andExpect(header().string("Cache-Control", "no-store"))
            .andExpect(jsonPath("$.data.body").value("Public body"))
            .andExpect(jsonPath("$.data.version").doesNotExist()).andExpect(jsonPath("$.data.hasDraft").doesNotExist());
        verify(contentService, never()).detail(anyString());
        String body = """
            {"title":"Draft title","body":"Draft body","version":6}
            """;
        mvc.perform(get("/api/v1/admin/content")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/content/about").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        mvc.perform(put("/api/v1/admin/content/about").header("Authorization", "Bearer owner").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/content/about/publish").header("Authorization", "Bearer owner").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/content/about/unpublish").header("Authorization", "Bearer owner").contentType("application/json").content("{\"version\":6}")).andExpect(status().isForbidden());
        mvc.perform(put("/api/v1/admin/content/about").header("Authorization", "Bearer admin").contentType("application/json").content(body)).andExpect(status().isOk());
        verify(contentService).saveDraft(eq("about"), argThat(r -> r.version() == 6 && r.body().equals("Draft body")));
        mvc.perform(post("/api/v1/admin/content/about/publish").header("Authorization", "Bearer admin").contentType("application/json").content(body)).andExpect(status().isOk());
        verify(contentService).publish(eq("about"), any());
        mvc.perform(post("/api/v1/admin/content/about/unpublish").header("Authorization", "Bearer admin").contentType("application/json").content("{\"version\":6}")).andExpect(status().isOk());
        verify(contentService).unpublish("about", 6L);
        mvc.perform(put("/api/v1/admin/content/about").header("Authorization", "Bearer admin").contentType("application/json").content("{}" )).andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/admin/content/about").header("Authorization", "Bearer admin").contentType("application/json").content(body.replace("Draft body", " "))).andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/admin/content/about").header("Authorization", "Bearer admin").contentType("application/json").content(body.replace("Draft body", "a".repeat(20001)))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/content/about/unpublish").header("Authorization", "Bearer admin").contentType("application/json").content("{\"version\":-1}")).andExpect(status().isBadRequest());
        when(contentService.published("contact")).thenThrow(new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Nội dung chưa công bố."));
        mvc.perform(get("/api/v1/content/contact")).andExpect(status().isNotFound());
    }

    @MockBean com.rental.modules.admin.service.AdminAreaService adminAreas;

    @Test void administrativeAreaManagementRequiresAdminAndValidInputs() throws Exception {
        String body = """
            {"name":"Phường kiểm thử","code":"TEST-AREA","type":"WARD","parentId":1}
            """;
        mvc.perform(get("/api/v1/admin/areas")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/areas").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/areas").header("Authorization", "Bearer owner").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(put("/api/v1/admin/areas/6").header("Authorization", "Bearer owner").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/admin/areas/6/status").header("Authorization", "Bearer owner").contentType("application/json").content("{\"active\":false}")).andExpect(status().isForbidden());
        mvc.perform(delete("/api/v1/admin/areas/6").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        verifyNoInteractions(adminAreas);
        mvc.perform(post("/api/v1/admin/areas").header("Authorization", "Bearer admin").contentType("application/json").content(body)).andExpect(status().isCreated());
        verify(adminAreas).create(argThat(r -> r.parentId() == 1 && r.type().equals("WARD")));
        mvc.perform(post("/api/v1/admin/areas").header("Authorization", "Bearer admin").contentType("application/json").content(body.replace("WARD", "INVALID"))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/areas").header("Authorization", "Bearer admin").contentType("application/json").content(body.replace("TEST-AREA", "bad code"))).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/areas/6/status").header("Authorization", "Bearer admin").contentType("application/json").content("{}")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/admin/areas").header("Authorization", "Bearer admin").param("parentId", "abc")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/admin/areas/parents").header("Authorization", "Bearer admin")).andExpect(status().isOk());
        mvc.perform(patch("/api/v1/admin/areas/6/status").header("Authorization", "Bearer admin").contentType("application/json").content("{\"active\":false}")).andExpect(status().isOk());
        verify(adminAreas).changeStatus(6L, false);
        mvc.perform(delete("/api/v1/admin/areas/6").header("Authorization", "Bearer admin")).andExpect(status().isOk());
        verify(adminAreas).delete(6L);
    }

    @Autowired MockMvc mvc;
    @MockBean com.rental.modules.admin.service.AdminUserService adminUsers;
    @MockBean com.rental.modules.admin.service.AdminCreateUserService adminCreation;
    @MockBean ListingService listings;
    @MockBean AdminListingService admin;
    @MockBean JwtService jwt;
    @MockBean CustomUserDetailsService users;
    @MockBean com.rental.modules.favorite.service.ListingFavoriteService favorites;
    @MockBean com.rental.modules.contract.service.ContractService leases;
    @MockBean com.rental.modules.listing.service.ListingExcelService listingExcel;
    @MockBean com.rental.modules.contract.service.ContractExcelService contractExcel;

    @MockBean com.rental.modules.notification.service.NotificationService notifications;

    @Test void creatingUsersRequiresAdminAndValidInput() throws Exception {
        String body = "{\"fullName\":\"New user\",\"email\":\"new@example.com\",\"password\":\"Password123!\",\"role\":\"MEMBER\"}";
        mvc.perform(post("/api/v1/admin/users").contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/users").header("Authorization", "Bearer owner")
            .contentType("application/json").content(body)).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/users").header("Authorization", "Bearer admin")
            .contentType("application/json").content("{}" )).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/users").header("Authorization", "Bearer admin")
            .contentType("application/json").content(body.replace("Password123!", "short"))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/users").header("Authorization", "Bearer admin")
            .contentType("application/json").content(body.replace("new@example.com", "invalid"))).andExpect(status().isBadRequest());
        User user = new User(); user.setUserId(7L); user.setEmail("new@example.com"); user.setFullName("New user");
        user.setRole(Role.MEMBER); user.setStatus(UserStatus.ACTIVE); user.setIsVerified(false);
        when(adminCreation.create(any())).thenReturn(com.rental.modules.admin.dto.response.AdminUserResponse.from(user));
        mvc.perform(post("/api/v1/admin/users").header("Authorization", "Bearer admin")
            .contentType("application/json").content(body)).andExpect(status().isCreated())
            .andExpect(jsonPath("$.data.verified").value(false)).andExpect(jsonPath("$.data.role").value("MEMBER"))
            .andExpect(jsonPath("$.data.passwordHash").doesNotExist()).andExpect(jsonPath("$.data.password").doesNotExist());
        verify(adminCreation).create(argThat(request -> request.role() == Role.MEMBER && request.email().equals("new@example.com")));
    }

    @Test void onlyAdminsCanManageUsersAndResponsesDoNotExposeSecrets() throws Exception {
        mvc.perform(get("/api/v1/admin/users")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/admin/users").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        mvc.perform(put("/api/v1/admin/users/1").header("Authorization", "Bearer owner")
            .contentType("application/json").content("{}" )).andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/admin/users/1/status").header("Authorization", "Bearer owner")
            .contentType("application/json").content("{\"status\":\"LOCKED\"}")).andExpect(status().isForbidden());
        User user = new User(); user.setUserId(1L); user.setRole(Role.MEMBER); user.setFullName("Tenant");
        user.setEmail("tenant@example.com"); user.setStatus(UserStatus.ACTIVE); user.setPasswordHash("private");
        var response = com.rental.modules.admin.dto.response.AdminUserResponse.from(user);
        when(adminUsers.search("", null, null, null, 0)).thenReturn(
            new com.rental.modules.admin.service.AdminUserService.UserPage(java.util.List.of(response), 1, 0, 1));
        mvc.perform(get("/api/v1/admin/users").header("Authorization", "Bearer admin"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.items[0].email").value("tenant@example.com"))
            .andExpect(jsonPath("$.data.items[0].passwordHash").doesNotExist())
            .andExpect(jsonPath("$.data.items[0].googleId").doesNotExist());
        mvc.perform(get("/api/v1/admin/users").param("role", "INVALID").header("Authorization", "Bearer admin"))
            .andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/admin/users/1").header("Authorization", "Bearer admin")
            .contentType("application/json").content("{\"fullName\":\"\",\"role\":\"MEMBER\"}"))
            .andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/admin/users/1").header("Authorization", "Bearer admin")
            .contentType("application/json").content("{\"fullName\":\"Name\",\"phoneNumber\":\"abc\",\"role\":\"MEMBER\"}"))
            .andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/users/1/status").header("Authorization", "Bearer admin")
            .contentType("application/json").content("{}" )).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/admin/users/1/status").header("Authorization", "Bearer admin")
            .contentType("application/json").content("{\"status\":\"LOCKED\"}")).andExpect(status().isOk());
        verify(adminUsers).changeStatus(1L, 2L, UserStatus.LOCKED);
    }

    @Test void existingTokensAreRejectedWhenAccountIsLockedOrUnverified() throws Exception {
        var user = ((CustomUserDetails) users.loadUserByUsername("owner")).getUser();
        user.setStatus(UserStatus.LOCKED);
        mvc.perform(get("/api/v1/listings/me").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        user.setStatus(UserStatus.ACTIVE); user.setIsVerified(false);
        mvc.perform(get("/api/v1/listings/me").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        user.setIsVerified(true);
        mvc.perform(get("/api/v1/listings/me").header("Authorization", "Bearer owner")).andExpect(status().isOk());
    }

    @Test void notificationsRequireLoginAreAccountScopedAndBroadcastIsAdminOnly() throws Exception {
        mvc.perform(get("/api/v1/notifications")).andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/notifications/7/read")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/notifications").header("Authorization", "Bearer owner").param("userId", "999"))
            .andExpect(status().isOk());
        verify(notifications).inbox(1L, 0, false);
        mvc.perform(patch("/api/v1/notifications/7/read").header("Authorization", "Bearer owner"))
            .andExpect(status().isOk());
        verify(notifications).markRead(1L, 7L);
        mvc.perform(patch("/api/v1/notifications/read-all").header("Authorization", "Bearer owner"))
            .andExpect(status().isOk());
        verify(notifications).markAllRead(1L);
        mvc.perform(patch("/api/v1/notifications/7/unread")).andExpect(status().isForbidden());
        mvc.perform(delete("/api/v1/notifications/7")).andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/notifications/7/unread").header("Authorization", "Bearer owner")).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/notifications/7").header("Authorization", "Bearer owner").param("userId", "999")).andExpect(status().isOk());
        mvc.perform(delete("/api/v1/notifications/read").header("Authorization", "Bearer owner")).andExpect(status().isOk());
        verify(notifications).markUnread(1L, 7L); verify(notifications).delete(1L, 7L); verify(notifications).deleteRead(1L);
        mvc.perform(post("/api/v1/admin/notifications/broadcast").header("Authorization", "Bearer owner")
            .contentType("application/json").content("{\"title\":\"Thông báo\",\"content\":\"Nội dung\"}"))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/notifications/broadcast").header("Authorization", "Bearer admin")
            .contentType("application/json").content("{\"title\":\"\",\"content\":\"Nội dung\"}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/admin/notifications/broadcast").header("Authorization", "Bearer admin")
            .contentType("application/json").content("{\"title\":\"Thông báo\",\"content\":\"Nội dung\"}"))
            .andExpect(status().isOk());
        verify(notifications).broadcast("Thông báo", "Nội dung");
    }

    @Test void excelRequiresLoginAndAlwaysUsesCurrentAccount() throws Exception {
        mvc.perform(get("/api/v1/listings/excel/export")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/contracts/excel/template")).andExpect(status().isForbidden());
        var file = new org.springframework.mock.web.MockMultipartFile("file", "test.xlsx", null, new byte[]{1});
        mvc.perform(multipart("/api/v1/listings/excel/import").file(file)).andExpect(status().isForbidden());
        mvc.perform(multipart("/api/v1/contracts/excel/import").file(file)).andExpect(status().isForbidden());
        mvc.perform(multipart("/api/v1/listings/excel/preview").file(file).param("ownerId", "999")
            .header("Authorization", "Bearer owner")).andExpect(status().isOk());
        verify(listingExcel).preview(eq(1L), any());
        mvc.perform(multipart("/api/v1/contracts/excel/import").file(file).param("ownerId", "999")
            .header("Authorization", "Bearer owner")).andExpect(status().isOk());
        verify(contractExcel).importContracts(eq("owner"), eq(1L), any());
        when(listingExcel.exportListings(1L)).thenReturn(new byte[]{1,2});
        mvc.perform(get("/api/v1/listings/excel/export").header("Authorization", "Bearer owner"))
            .andExpect(status().isOk()).andExpect(header().string("Content-Disposition", "attachment; filename=\"tin-dang.xlsx\""));
    }

    @Test void contractsRequireAuthenticationAndValidateRequests() throws Exception {
        mvc.perform(get("/api/v1/contracts/me")).andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/contracts/preview").contentType("application/json").content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/contracts/preview").header("Authorization","Bearer owner")
                .contentType("application/json")
                .content("{\"listingId\":1,\"tenantId\":2,\"startDate\":\"2027-01-01\",\"endDate\":\"2028-01-01\",\"monthlyRent\":5000000,\"depositAmount\":0}"))
                .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/contracts").header("Authorization","Bearer owner")
                .contentType("application/json").content("{}")).andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/contracts/1/status").header("Authorization","Bearer owner")
                .contentType("application/json").content("{\"status\":\"ACTIVE\"}")).andExpect(status().isBadRequest());
        verifyNoInteractions(leases);
    }

    @BeforeEach void tokens() {
        for (String token : new String[]{"owner", "admin"}) {
            User user = new User(); user.setUserId(token.equals("owner") ? 1L : 2L);
            user.setEmail(token); user.setRole(token.equals("admin") ? Role.ADMIN : Role.MEMBER);
            user.setStatus(UserStatus.ACTIVE); user.setIsVerified(true);
            var details = new CustomUserDetails(user);
            when(jwt.extractEmail(token)).thenReturn(token);
            when(users.loadUserByUsername(token)).thenReturn(details);
        }
        when(jwt.isTokenValid(anyString(), any())).thenReturn(true);
    }

    @Test void publicMapAndListingsNeedNoToken() throws Exception {
        mvc.perform(get("/api/v1/listings/public/10")).andExpect(status().isOk());
        mvc.perform(get("/api/v1/listings/public")).andExpect(status().isOk());
        mvc.perform(get("/api/v1/listings/map").param("minLat", "10.7").param("minLng", "106.6")
                .param("maxLat", "10.9").param("maxLng", "106.8")).andExpect(status().isOk());
    }

    @Test void favoritesRequireAuthenticationAndUseCurrentUser() throws Exception {
        mvc.perform(put("/api/v1/listings/10/favorite")).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/listings/favorites/me")).andExpect(status().isForbidden());
        mvc.perform(put("/api/v1/listings/10/favorite").header("Authorization", "Bearer owner"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.isFavorite").value(true));
        verify(favorites).save(1L, 10L);
        mvc.perform(delete("/api/v1/listings/10/favorite").header("Authorization", "Bearer owner"))
                .andExpect(status().isOk());
        verify(favorites).remove(1L, 10L);
    }

    @Test void ownerCannotAccessAnyAdminModerationEndpoint() throws Exception {
        mvc.perform(get("/api/v1/admin/listings/pending").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/admin/listings/10/approve").header("Authorization", "Bearer owner")).andExpect(status().isForbidden());
        verifyNoInteractions(admin);
    }

    @Test void adminCanApproveAndOwnerCanReadOwnListings() throws Exception {
        mvc.perform(patch("/api/v1/admin/listings/10/approve").header("Authorization", "Bearer admin")).andExpect(status().isOk());
        verify(admin).approveListing(10L, 2L);
        mvc.perform(get("/api/v1/listings/me").header("Authorization", "Bearer owner")).andExpect(status().isOk());
        verify(listings).getMyListings(1L);
    }

    @Test void anonymousCannotManageListings() throws Exception {
        mvc.perform(get("/api/v1/listings/me")).andExpect(status().isForbidden());
        mvc.perform(delete("/api/v1/listings/10")).andExpect(status().isForbidden());
    }

    @Test void invalidListingAndRentalStatusReturnBadRequest() throws Exception {
        mvc.perform(post("/api/v1/listings").header("Authorization", "Bearer owner")
                .contentType("application/json").content("{}")) .andExpect(status().isBadRequest());
        mvc.perform(patch("/api/v1/listings/10/rental-status").header("Authorization", "Bearer owner")
                .contentType("application/json").content("{\"rentalStatus\":\"DELETED\"}")) .andExpect(status().isBadRequest());
    }
    @Test void sharedRoomRejectsMissingOrFullOccupancyAndAcceptsValidDetails() throws Exception {
        String body = """
            {"title":"Ở ghép", "listingType":"SHARED_ROOM", "rentPrice":1500000,
             "areaSqm":25,"areaId":6,"address":"TP.HCM","latitude":10.78,"longitude":106.7,
             "imageUrls":["https://example.com/shared.jpg"],"genderPreference":"ANY",
             "currentOccupants":1,"maxOccupants":2}
            """;
        mvc.perform(post("/api/v1/listings").header("Authorization", "Bearer owner")
                .contentType("application/json").content(body.replace("\"maxOccupants\":2", "\"maxOccupants\":1")))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(listings);
        mvc.perform(post("/api/v1/listings").header("Authorization", "Bearer owner")
                .contentType("application/json").content(body)).andExpect(status().isCreated());
        verify(listings).createListing(eq(1L), any());
    }
}
