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

@WebMvcTest({ListingController.class, AdminListingController.class,
        com.rental.modules.favorite.controller.ListingFavoriteController.class,
        com.rental.modules.contract.controller.ContractController.class})
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class ListingSecurityTest {
    @Autowired MockMvc mvc;
    @MockBean ListingService listings;
    @MockBean AdminListingService admin;
    @MockBean JwtService jwt;
    @MockBean CustomUserDetailsService users;
    @MockBean com.rental.modules.favorite.service.ListingFavoriteService favorites;
    @MockBean com.rental.modules.contract.service.ContractService leases;
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
            user.setEmail(token); user.setRole(token.equals("admin") ? Role.ADMIN : Role.USER);
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
}
