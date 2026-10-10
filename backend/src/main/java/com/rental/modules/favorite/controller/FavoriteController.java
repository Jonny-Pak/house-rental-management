package com.rental.modules.favorite.controller;

import com.rental.modules.favorite.service.FavoriteService;
import com.rental.modules.property.dto.response.PropertyResponse;
import com.rental.modules.user.dto.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/favorites")
public class FavoriteController {

    private final FavoriteService favoriteService;

    public FavoriteController(FavoriteService favoriteService) {
        this.favoriteService = favoriteService;
    }


    /**
     * Toggle favorite status of a property.
     * POST /api/v1/favorites/{propertyId}
     */
    @PostMapping("/{propertyId}")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> toggleFavorite(
            Principal principal,
            @PathVariable Long propertyId) {

        boolean isFavorite = favoriteService.toggleFavorite(principal.getName(), propertyId);

        String message = isFavorite
                ? "ÄÃ£ thÃªm khu trá» vÃ o danh sÃ¡ch yÃªu thÃ­ch."
                : "ÄÃ£ xÃ³a khu trá» khá»i danh sÃ¡ch yÃªu thÃ­ch.";

        return ResponseEntity.ok(ApiResponse.success(message, Map.of("isFavorite", isFavorite)));
    }

    /**
     * Get all favorited properties for the authenticated user.
     * GET /api/v1/favorites/me
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<List<PropertyResponse>>> getMyFavorites(Principal principal) {
        List<PropertyResponse> favorites = favoriteService.getMyFavoriteProperties(principal.getName());
        return ResponseEntity.ok(ApiResponse.success("Láº¥y danh sÃ¡ch yÃªu thÃ­ch thÃ nh cÃ´ng.", favorites));
    }
}
