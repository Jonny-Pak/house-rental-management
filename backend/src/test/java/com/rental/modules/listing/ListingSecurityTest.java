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

@WebMvcTest({ListingController.class, AdminListingController.class})
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class ListingSecurityTest {
    @Autowired MockMvc mvc;
    @MockBean ListingService listings;
    @MockBean AdminListingService admin;
    @MockBean JwtService jwt;
    @MockBean CustomUserDetailsService users;

    @BeforeEach void tokens() {
        for (String token : new String[]{"owner", "admin"}) {
            User user = new User(); user.setUserId(token.equals("owner") ? 1L : 2L);
            user.setEmail(token); user.setRole(token.equals("admin") ? Role.ADMIN : Role.USER);
            user.setStatus(UserStatus.ACTIVE); user.setIsVerified(true);
            var details = new CustomUserDetails(user);
            when(jwt.extractEmail(token)).thenReturn(token);
            when(users.loadUserByUsername(token)).thenReturn(details);
        }
        when(jwt.isTokenValid(anyString(), any())).thenReturn(true);
    }

    @Test void publicMapAndListingsNeedNoToken() throws Exception {
        mvc.perform(get("/api/v1/listings/public")).andExpect(status().isOk());
        mvc.perform(get("/api/v1/listings/map").param("minLat", "10.7").param("minLng", "106.6")
                .param("maxLat", "10.9").param("maxLng", "106.8")).andExpect(status().isOk());
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
}
