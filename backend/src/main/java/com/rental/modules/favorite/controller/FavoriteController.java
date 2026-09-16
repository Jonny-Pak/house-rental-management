package com.rental.modules.favorite.controller;

import com.rental.modules.favorite.service.FavoriteService;
import com.rental.modules.property.dto.response.PropertyResponse;
import com.rental.modules.user.dto.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/favorites")
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteService favoriteService;

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
                ? "Đã thêm khu trọ vào danh sách yêu thích."
                : "Đã xóa khu trọ khỏi danh sách yêu thích.";

        return ResponseEntity.ok(ApiResponse.success(message, Map.of("isFavorite", isFavorite)));
    }

    /**
     * Get all favorited properties for the authenticated user.
     * GET /api/v1/favorites/me
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<List<PropertyResponse>>> getMyFavorites(Principal principal) {
        List<PropertyResponse> favorites = favoriteService.getMyFavoriteProperties(principal.getName());
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách yêu thích thành công.", favorites));
    }
}
